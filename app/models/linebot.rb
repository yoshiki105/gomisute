require 'line/bot'

def client
  @client ||= Line::Bot::Client.new do |config|
    config.channel_id = ENV['LINE_CHANNEL_ID']
    config.channel_secret = ENV['LINE_CHANNEL_SECRET']
    config.channel_token = ENV['LINE_CHANNEL_TOKEN']
  end
end

def validate_client_signature(body)
  signature = request.env['HTTP_X_LINE_SIGNATURE']
  head :bad_request unless client.validate_signature(body, signature)
end

def push(user, text)
  message = {
    type: 'text',
    text: text
  }
  @response = client.push_message(user.line_id, message)
end

def respond_to_user
  body = request.body.read
  validate_client_signature(body)

  events = client.parse_events_from(body)
  events.each do |event|
    case event
    when Line::Bot::Event::Message
      @response = Response.new
      case event.type
      when Line::Bot::Event::MessageType::Text
        @user = User.find_or_create_by(line_id: event['source']['userId'])
        replied_message = event.message['text']
        # 0が送られたら、常にトップに戻る TODO: メソッドに切り出す
        @user.top! if replied_message.match(/^[0０]$/)

        ## リプライによる条件分岐開始 ##
        case @user.mode
        when 'top'
          case replied_message
          when '0', '０'
            @response.add_cancel_message
          when '1', '１'
            @response.add_asking_trash_name_message
            @user.registration!
          when '2', '２'
            @response.add_show_trashes_message(@user)
          when '3', '３'
            @response.add_edit_message(@user)
            @user.which_trash_to_edit!
          when '4', '４'
            @response.add_next_trash_colleciton_day_message
          else
            @response.add_alert_message
          end
        ### 登録モード ###
        when 'registration'
          @user.messages.create!(text: replied_message)
          @response.add_day_of_week_message(replied_message)
          @user.add_day_of_week!
        when 'add_day_of_week' # TODO: 回収日複数の実装
          if replied_message.match(/^[1-7]$/)
            @user.messages.create!(text: replied_message) # TODO: メソッドにする => @user.save_message(replied_message)
            trash_name = @user.messages[-2].text
            @response.add_cycle_message(trash_name)
            @user.add_cycle!
          else
            @response.add_alert_message
          end
        when 'add_cycle'
          if replied_message.match(/^[1-5]$/)
            @user.messages.create!(text: replied_message)
            trash_name = @user.messages[-3].text
            # TODO: メソッドにする => @user.choose_day_of_week
            collection_day = CollectionDay.find_by(day_of_week: @user.messages[-2].text)
            now_week_num = Time.zone.today.strftime('%W').to_i
            # TODO: 命名更 => 登録予定の周期
            cycle_name = case @user.messages[-1].text # TODO: メソッドにする => @user.choose_cycle
                         when '1' then :every_week
                         when '2' then now_week_num.even? ? :even_weeks : :odd_weeks
                         when '3' then now_week_num.odd? ? :even_weeks : :odd_weeks
                         when '4' then :first_and_third
                         when '5' then :second_and_fourth
                         end
            cycle = Cycle.find_by(name: cycle_name)
            @trash = @user.trashes.create!(name: trash_name, cycle: cycle, collection_days: [collection_day])
            @response.add_registration_completed_message(@trash)
            @user.top!
          else
            @response.add_alert_message
          end
        ### 編集モード ###
        when 'which_trash_to_edit'
          @user.messages.create!(text: replied_message)
          trash = @user.trashes[replied_message.to_i - 1] # ユーザーが選択したゴミ => TODO: 命名変更

          @response.add_message_which_item_to_edit(trash)
          @user.which_item_to_edit!
        when 'which_item_to_edit'
          case replied_message
          when /^([1-3]|[１-３])$/
            @user.messages.create!(text: replied_message)
            items = %w[ゴミの名前 曜日 周期]
            item = items[replied_message.to_i - 1] #=> ユーザーが選択した項目 TODO: 命名変更
            trash = @user.trashes[replied_message.to_i - 2] # ユーザーが選択したゴミ => TODO: 命名変更
            @response.add_edit_item_message(item)

            case item
            when 'ゴミの名前'
              @response.add_asking_trash_name_message
            when '曜日'
              @response.add_day_of_week_message(trash.name)
            when '周期'
              @response.add_cycle_message(trash.name)
            end
            @user.edit_complete!
          when /^(4|４)$/
            @response.add_delete_confirm_message
            @user.delete_confirm!
          else
            @response.add_alert_message
          end
        when 'edit_complete'
          # TODO: 命名を考える
          # 変更対象のゴミのインスタンス @trash を決定する
          two_pre_message = @user.messages[-2].text
          @trash = @user.trashes[two_pre_message.to_i - 1] #=> 変更するゴミのインスタンス
          # 変更するゴミの項目 item を決定する
          items = %w[ゴミの名前 曜日 周期]
          one_pre_message = @user.messages[-1].text #=> 項目番号
          item = items[one_pre_message.to_i - 1] #=> 変更するゴミの項目
          edit_complete = lambda { # TODO: lambdaの必要ある？
            @response.add_edit_completed_message(@trash)
            @user.top!
          }
          # 変更操作
          case item
          when 'ゴミの名前'
            @trash.update!(name: replied_message)
            edit_complete.call
          when '周期'
            if replied_message.match(/^[1-5]$/)
              # 周期の決定
              now_week_num = Time.zone.today.strftime('%W').to_i
              cycle_name = case replied_message
                           when '1' then :every_week
                           when '2' then now_week_num.even? ? :even_weeks : :odd_weeks
                           when '3' then now_week_num.odd? ? :even_weeks : :odd_weeks
                           when '4' then :first_and_third
                           when '5' then :second_and_fourth
                           end
              @trash.cycle.update!(name: cycle_name)
              edit_complete.call
            else
              @response.add_alert_message
            end
          when '曜日'
            if replied_message.match(/^[1-7]$/)
              @trash.latest_collection_day.update!(day_of_week: replied_message.to_i)
              edit_complete.call
            else
              @response.add_alert_message
            end
          end
        when 'delete_confirm'
          if replied_message.match(/^[1１]$/)
            # 削除対象のゴミのインスタンス @trash を決定する
            pre_message = @user.messages[-1].text
            @trash = @user.trashes[pre_message.to_i - 1] #=> 変更するゴミのインスタンス
            @trash.destroy!
            @response.add_delete_completed_message
            @user.top!
          else
            @response.add_alert_message
          end
        end

        ## リプライによる条件分岐終了 ##
        @response.add_default_message if @user.top?

        reply_to_client(client, event['replyToken'], @response.text)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        @response.add_non_text_received_message
        reply_to_client(client, event['replyToken'], @response.text)
      end
    end
  end
  head :ok
end

def reply_to_client(client, reply_token, message)
  response_message = {
    type: 'text',
    text: message
  }
  client.reply_message(reply_token, response_message)
end
