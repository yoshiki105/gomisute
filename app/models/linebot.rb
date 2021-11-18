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
      case event.type
      when Line::Bot::Event::MessageType::Text
        @user = User.find_or_create_by(line_id: event['source']['userId'])
        replied_message = event.message['text']
        @response = ''

        # 0が送られたら、常にトップに戻る TODO: メソッドに切り出す
        @user.top! if replied_message.match(/^[0０]$/)

        ## リプライによる条件分岐開始 ##
        case @user.mode
        when 'top'
          case replied_message
          when '0', '０'
            @response += "中止だね！\n"
          when '1', '１' # ゴミ登録
            @response += <<~TEXT
              ゴミの登録だね！
              何のゴミを登録する？一つだけ答えてね！
              (例)燃えるゴミ
            TEXT
            @user.registration!
          when '2', '２' # 登録してあるゴミの一覧表示
            @response += <<~TEXT
              登録内容の確認だね！
              今登録している内容は以下の通りだよ！
              #{@user.show_trashes}
            TEXT
          when '3', '３' # 内容編集
            @response += <<~TEXT
              登録内容の編集だね！
              どれを編集する？
              #{@user.show_editable_trashes}
            TEXT
            @user.which_trash_to_edit!
          when '4', '４' # 次回確認
            @response += <<~TEXT
              ## この機能は未実装です ##
              次回のゴミ収集日は、
                燃えるゴミ
                毎週
                月曜日・木曜日
              だよ！
              当日の朝6時に通知するからね！
            TEXT
          else
            @response += "正しく入力してね！\n"
          end
        ### 登録モード ###
        when 'registration'
          @user.messages.create!(text: replied_message) # ユーザーの返信内容をDBへ保存

          @response += <<~TEXT
            「#{replied_message}」を登録するね！
            収集日はいつかな？
              1: 月曜日
              2: 火曜日
              3: 水曜日
              4: 木曜日
              5: 金曜日
              6: 土曜日
              7: 日曜日
              0: ゴミの登録をやめる\n
          TEXT
          @user.add_day_of_week!
        when 'add_day_of_week' # TODO: 回収日複数の実装
          if replied_message.match(/^[1-7]$/)
            @user.messages.create!(text: replied_message) # TODO: メソッドにする => @user.save_message(replied_message)
            trash_name = @user.messages[-2].text

            @response += <<~TEXT
              次に、「#{trash_name}」の周期を教えてね！
                1: 毎週
                2: 今週から隔週
                3: 来週から隔週
                4: 第１・３
                5: 第２・４
                0: やめる
            TEXT
            @user.add_cycle!
          else
            @response += "正しく入力してね！\n"
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

            @response += <<~TEXT
              「#{@trash.name}」の収集日は
              「#{@trash.cycle.name_i18n}」の「#{collection_day.day_of_week_i18n}」だね！
              登録したよ！
            TEXT
            @user.top!
          else
            @response += "正しく入力してね！\n"
          end
        ### 編集モード ###
        when 'which_trash_to_edit'
          @user.messages.create!(text: replied_message)
          trash = @user.trashes[replied_message.to_i - 1] # ユーザーが選択したゴミ => TODO: 命名変更

          @response += <<~TEXT
            「#{trash.name}」が選択されたよ！
            どの項目を編集する？
              1: 収集物の名前
              2: 周期
              3: 曜日
              4: #{trash.name}の登録を削除する
              0: 編集をやめる
          TEXT
          @user.which_item_to_edit!
        when 'which_item_to_edit'
          case replied_message
          when /^([1-3]|[１-３])$/
            @user.messages.create!(text: replied_message)
            items = %w[ゴミの名前 周期 曜日]
            item = items[replied_message.to_i - 1] #=> ユーザーが選択した項目 TODO: 命名変更
            @response += "変更するのは「#{item}」だね！\n"

            case item
            when 'ゴミの名前'
              @response += <<~TEXT
                どんな名前にする？（例）燃えないゴミ
              TEXT
            when '周期'
              @response += <<~TEXT
                周期をどれに変更する？
                  1: 毎週
                  2: 今週から隔週
                  3: 来週から隔週
                  4: 第１・３
                  5: 第２・４
                  0: やめる
              TEXT
            when '曜日'
              @response += <<~TEXT
                収集日をいつに変更する？
                  1: 月曜日
                  2: 火曜日
                  3: 水曜日
                  4: 木曜日
                  5: 金曜日
                  6: 土曜日
                  7: 日曜日
                  0: やめる
              TEXT
            end
            @user.edit_complete!
          when /^(4|４)$/
            @response += <<~TEXT
              本当に削除してよろしいですか？
              元には戻せません。
                1: 削除を実行する
                0: 中止する
            TEXT
            @user.delete_confirm!
          else
            @response += "正しく入力してね！\n"
          end
        when 'edit_complete'
          # TODO: 命名を考える
          # 変更対象のゴミのインスタンス @trash を決定する
          two_pre_message = @user.messages[-2].text
          @trash = @user.trashes[two_pre_message.to_i - 1] #=> 変更するゴミのインスタンス
          # 変更するゴミの項目 item を決定する
          items = %w[ゴミの名前 周期 曜日]
          one_pre_message = @user.messages[-1].text #=> 項目番号
          item = items[one_pre_message.to_i - 1] #=> 変更するゴミの項目
          edit_complete = lambda {
            @response += <<~TEXT
              編集完了したよ！
              新しい登録内容は、
                #{@trash.name}
                #{@trash.cycle.name_i18n}
                #{@trash.latest_collection_day.day_of_week_i18n}
              だよ！\n
            TEXT
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
              @response += "正しく入力してね！\n"
            end
          when '曜日'
            if replied_message.match(/^[1-7]$/)
              @trash.latest_collection_day.update!(day_of_week: replied_message.to_i)
              edit_complete.call
            else
              @response += "正しく入力してね！\n"
            end
          end
        when 'delete_confirm'
          if replied_message.match(/^[1１]$/)
            # 削除対象のゴミのインスタンス @trash を決定する
            pre_message = @user.messages[-1].text
            @trash = @user.trashes[pre_message.to_i - 1] #=> 変更するゴミのインスタンス
            @trash.destroy!
            @response += "削除が完了したよ！\n"
            @user.top!
          else
            @response += "正しく入力してね！\n"
          end
        end

        ## リプライによる条件分岐終了 ##
        if @user.top? # TODO: 丸ごとメソッドにできそう
          @response += <<~TEXT
            #{'=' * 15}
            次はどうする？
            ↓↓番号を選択↓↓
              1. ゴミの登録
              2. 登録内容の確認
              3. 登録内容の編集
              4. 次回のゴミ収集日の確認
          TEXT
        end

        message = { # TODO: 命名変更 => response_message
          type: 'text',
          text: @response
        }
        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
        message = {
          type: 'text',
          text: '画像や動画は対応してません。'
        }
        client.reply_message(event['replyToken'], message)
      end
    end
  end
  head :ok
end
