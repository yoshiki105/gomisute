user = User.create!(
  line_id: ENV['MY_LINE_ID'],
)
day_str = %w[nil 月 火 水 木 金 土 日]
cycle_str = %w[nil 毎週 奇数隔週 偶数隔週 第1・3 第2・4]

# 単数曜日、全ての周期のseed
(1..5).each do |cycle_num|
	cycle = Cycle.find(cycle_num)
  (1..7).each do |day_num|
		day = CollectionDay.find(day_num)
		trash = Trash.create!(name: "#{cycle_str[cycle_num]}:#{day_str[day_num]}曜日のゴミ", user: user, cycle: cycle, collection_days: [day])
    hours, minutes = rand(0..23), rand(0..5) * 10
    Notification.create!(trash: trash, notify_at: "#{hours}:#{minutes}")
  end
end

# 複数曜日、毎週のseed
cycle = Cycle.find(1)
(1..3).each do |num|
  hours, minutes = rand(0..23), rand(0..5) * 10
  day = CollectionDay.find([num, (8 - num)])
  trash = Trash.create!(name: "#{day_str[num]}・#{day_str[(8 - num)]}曜日のゴミ", user: user, cycle: cycle, collection_days: day)
  Notification.create!(trash: trash, notify_at: "#{hours}:#{minutes}")

  day = CollectionDay.find([num, (7 - num)])
  trash = Trash.create!(name: "#{day_str[num]}・#{day_str[(7 - num)]}曜日のゴミ", user: user, cycle: cycle, collection_days: day)
  Notification.create!(trash: trash, notify_at: "#{hours}:#{minutes}")
end
