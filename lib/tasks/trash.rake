namespace :trash do
  desc '今日捨てるゴミがあるかどうかチェックする'
  task check_today: :environment do
    todays_day = Date.today.strftime('%A').downcase # 今日の曜日(文字列)

    # 通知するべきuserを特定
    users = CollectionDay.where(day_of_week: todays_day).map(&:user)
    users.each do |user|
      # userの持っているtrashesに対して、今日捨てるべきtrashesのname群を返す
      trashes_name = user.trashes.select { |trash| trash.is_thrown_away?(todays_day) }.pluck(:name)

      text = <<~EOS
        本日はゴミ捨ての日です！
        以下を確認して捨てる準備しましょう！
        ==============================
      EOS

      trashes_name.each do |name|
        text << "#{name}\n"
        text << "==============================\n"
      end

      # userに通知を送る
      linebot = LinebotController.new
      linebot.push(user, text)
    end
  end
end
