require 'line/bot'

class LinebotController < ApplicationController
  # before_action :set_line, only: [:show, :edit, :update, :destroy]
  # protect_from_forgery with: :null_session

  def callback
    client ||= Line::Bot::Client.new { |config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }

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
              ################ 登録してあるゴミのリストを表示する #####################
              response += '登録内容の編集だね！
              どれを編集する？
              ==============================
              1:
                燃えるゴミ
                毎週
                月曜日・木曜日
              ==============================
              2:
                燃えないゴミ
                毎週
                水曜日
              ==============================
              3:
                衣類
                第一・四
                木曜日
              ==============================
              0: 編集を中止する'
              @user.edit!
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
            @user.trashes.create!(name: text)
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
            # 一個前のリクエストから、@trashをどうやって保持する？ ↓最新のTrash
            @trash = @user.latest_trash

            case text
            when '1', '１'; @trash.collection_days.create!(day_of_week: :monday)
            when '2', '２'; @trash.collection_days.create!(day_of_week: :tuesday)
            when '3', '３'; @trash.collection_days.create!(day_of_week: :wednesday)
            when '4', '４'; @trash.collection_days.create!(day_of_week: :thursday)
            when '5', '５'; @trash.collection_days.create!(day_of_week: :friday)
            when '6', '６'; @trash.collection_days.create!(day_of_week: :saturday)
            when '7', '７'; @trash.collection_days.create!(day_of_week: :sunday)
            else
              response += "数字で入力してね！\n"
            end

            if text =~ /^([1-7]|[１-７])$/
              response +=  <<~EOS
                「#{@trash.name}」の収集日は「#{@trash.latest_collection_day.day_of_week_i18n}」だね！
                次に、周期を教えてね！
                  1: 毎週
                  2: 隔週
                  3: 第１・３
                  4: 第２・４
                  0: やめる
              EOS

              @user.add_cycle!
            end
          when 'add_cycle'
            @trash = @user.latest_trash
            @collection_day = @trash.latest_collection_day

            case text
            when '1', '１'; @collection_day.update!(cycle: :every_week)
            when '2', '２'; @collection_day.update!(cycle: :every_other_week)
            when '3', '３'; @collection_day.update!(cycle: :first_and_third)
            when '4', '４'; @collection_day.update!(cycle: :second_and_fourth)
            else
              response += "数字で入力してね！\n"
            end

            if text =~ /^([1-4]|[１-４])$/
              response +=  <<~EOS
                「#{@trash.name}」の収集日は「#{@collection_day.cycle_i18n}」の「#{@collection_day.day_of_week_i18n}」だね！
                登録したよ！
              EOS
              @user.top!
            end
          ### 編集モード ###
          when 'edit'
            response += "登録内容を編集するモードです。\n"
            response += "入力されたテキストは#{text}です。\n"
          end

          if @user.top?
            # モード選択を問う
            response +=  <<~EOS
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
