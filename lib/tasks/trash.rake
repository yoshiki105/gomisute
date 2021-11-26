namespace :trash do
  desc '今日捨てるゴミがあるかどうかチェックする'
  task :check_today, ['test'] => :environment do |_, args|
    now_at = Time.current.floor(10.minutes).to_s(:time)
    todays_date = Time.zone.today
    youbi = todays_date.strftime('%A').downcase #=> "sunday" 今日の曜日
    date = todays_date.strftime('%-d') #=> "14" 今日の日付
    nansyu = (date.to_i - 1) / 7 + 1 #=> 2 今日が第何週か
    # youbi, nansyu, now_atから今日捨てるべきTrashのコレクションを作成
    todays_trashes = Trash.throw_away(nansyu, youbi, now_at)

    # 通知テストの時
    if args['test']
      users = [User.find_by(line_id: ENV['MY_LINE_ID'])]
    else
      user_ids = todays_trashes.group(:user_id).pluck(:user_id)
      users = User.find(user_ids) # 通知するべきUserのコレクションを作成
    end

    # Userごとにtextを組み立てて通知を送る
    users&.each do |user|
      trashes_name = todays_trashes.search_with_user(user).pluck(:name)

      text = <<~TEXT
        本日はゴミ捨ての日です！
        以下を確認して捨てる準備しましょう！
        #{'=' * 15}
      TEXT

      trashes_name.each do |name|
        text << "#{name}\n"
        text << "#{'=' * 15}\n"
      end

      # userに通知を送る
      linebot = Linebot.new
      linebot.push(user, text)
    end
  end
end
