require 'line/bot'

class LinebotController < ApplicationController
  # before_action :set_line, only: [:show, :edit, :update, :destroy]
  # protect_from_forgery with: :null_session

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end


  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          # 初回ユーザーなら登録する
          @user = User.find_or_create_by(line_id: event['source']['userId'])

          # ここからレスポンス組立
          text = event.message['text']
          response = ''

          # 0が送られたら、常にトップに戻る
          @user.top! if text.eql?('0') || text.eql?('０')

          # @user.mode の値で前回のやり取りを確認
          case @user.mode
          when 'top'
            case text
            when '0', '０'
              response += "中止だね！\n"
            when '1', '１' # ゴミ登録
              response +=  <<~EOS
                ゴミの登録だね！
                何のゴミを登録する？一つだけ答えてね！
                (例)燃えるゴミ
              EOS
              @user.registration!
            when '2', '２' # 登録してあるゴミの一覧表示
              response +=  <<~EOS
                登録内容の確認だね！
                今登録している内容は以下の通りだよ！
                #{@user.show_trashes}
              EOS

            when '3', '３' # 内容編集
              response +=  <<~EOS
                登録内容の編集だね！
                どれを編集する？
                #{@user.show_editable_trashes}
              EOS
              @user.which_trash_to_edit!

            when '4', '４' # 次回確認
              response += "次回のゴミ収集日は、
                燃えるゴミ
                毎週
                月曜日・木曜日
              だよ！
              当日の朝6時に通知するからね！
              \n"
            else
              response += "正しく入力してね！\n"
            end
          ### 登録モード ###
          when 'registration'
            @user.messages.create!(text: text) # ユーザーの返信内容をDBへ保存

            response +=  <<~EOS
              「#{text}」を登録するね！
              収集日はいつかな？
                1: 月曜日
                2: 火曜日
                3: 水曜日
                4: 木曜日
                5: 金曜日
                6: 土曜日
                7: 日曜日
                0: ゴミの登録をやめる\n
            EOS

            @user.add_day_of_week!
          when 'add_day_of_week'
            # 回収日複数は後で実装予定
            if text =~ /^([1-7]|[１-７])$/
              @user.messages.create!(text: text) # ユーザーの返信内容をDBへ保存
              trash_name = @user.messages[-2].text

              response +=  <<~EOS
                次に、「#{trash_name}」の周期を教えてね！
                  1: 毎週
                  2: 隔週
                  3: 第１・３
                  4: 第２・４
                  0: やめる
              EOS

              @user.add_cycle!
            end
          when 'add_cycle'
            if text =~ /^([1-4]|[１-４])$/
              @user.messages.create!(text: text) # ユーザーの返信内容をDBへ保存
              # ゴミの名前の決定
              trash_name = @user.messages[-3].text
              # 曜日の決定
              day_of_week = case @user.messages[-2].text
                when '1', '１';  :monday
                when '2', '２';  :tuesday
                when '3', '３';  :wednesday
                when '4', '４';  :thursday
                when '5', '５';  :friday
                when '6', '６';  :saturday
                when '7', '７';  :sunday
                end
              # 周期の決定
              cycle = case @user.messages[-1].text
                when '1', '１'; :every_week
                when '2', '２'; :every_other_week
                when '3', '３'; :first_and_third
                when '4', '４'; :second_and_fourth
                end

              @trash = @user.trashes.create!(name: trash_name)
              @collection_day = @trash.collection_days.create!(day_of_week: day_of_week, cycle: cycle)

              response +=  <<~EOS
                「#{@trash.name}」の収集日は「#{@collection_day.cycle_i18n}」の「#{@collection_day.day_of_week_i18n}」だね！
                登録したよ！
              EOS
              @user.top!
            else
              response += "正しく入力してね！\n"
            end
          ### 編集モード ###
          when 'which_trash_to_edit'
            @user.messages.create!(text: text) # ユーザーの返信内容をDBへ保存
            trash = @user.trashes[text.to_i - 1] #=> ユーザーが選択したゴミ

            response +=  <<~EOS
              「#{trash.name}」が選択されたよ！
              どの項目を編集する？
                1: 収集物の名前
                2: 周期
                3: 曜日
                0: 編集をやめる
            EOS

            @user.which_item_to_edit!

          when 'which_item_to_edit'
            @user.messages.create!(text: text) # ユーザーの返信内容をDBへ保存
            items = ['ゴミの名前', '周期', '曜日']
            item = items[text.to_i - 1] #=> ユーザーが選択した項目
            response +=  "変更するのは「#{item}」だね！\n"

            case item
            when 'ゴミの名前'
              response +=  <<~EOS
                どんな名前にする？（例）燃えないゴミ
              EOS
            when '周期'
              response +=  <<~EOS
                周期をどれに変更する？
                  1: 毎週
                  2: 隔週
                  3: 第１・３
                  4: 第２・４
                  0: やめる
              EOS
            when '曜日'
              response +=  <<~EOS
                収集日をいつに変更する？
                  1: 月曜日
                  2: 火曜日
                  3: 水曜日
                  4: 木曜日
                  5: 金曜日
                  6: 土曜日
                  7: 日曜日
                  0: やめる
              EOS
            end

            @user.edit_complete!

          when 'edit_complete'
            # 変更対象のゴミのインスタンス @trash を決定する
            two_pre_message = @user.messages[-2].text
            @trash = @user.trashes[two_pre_message.to_i - 1] #=> 変更するゴミのインスタンス
            # 変更するゴミの項目 item を決定する
            items = ['ゴミの名前', '周期', '曜日']
            one_pre_message = @user.messages[-1].text #=> 項目番号
            item = items[one_pre_message.to_i - 1] #=> 変更するゴミの項目

            # 変更操作
            case item
            when 'ゴミの名前'
              @trash.update!(name: text)
            when '周期'
              @trash.latest_collection_day.update!(cycle: text.to_i)
            when '曜日'
              @trash.latest_collection_day.update!(day_of_week: text.to_i)
            end

            response += <<~EOS
              編集完了したよ！
              新しい登録内容は、
                #{@trash.name}
                #{@trash.latest_collection_day.cycle_i18n}
                #{@trash.latest_collection_day.day_of_week_i18n}
              だよ！\n
            EOS

            @user.top!
          end

          if @user.top?
            # モード選択を問う
            response +=  <<~EOS
                =============================
                次はどうする？
                ↓↓番号を選択↓↓
                  1. ゴミの登録
                  2. 登録内容の確認
                  3. 登録内容の編集
                  4. 次回のゴミ収集日の確認
            EOS
          end

          # responseを組み立てた結果を返す
          message = {
            type: 'text',
            text: response
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
end
