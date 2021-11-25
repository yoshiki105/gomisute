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
		Trash.create!(name: "#{cycle_str[cycle_num]}:#{day_str[day_num]}曜日のゴミ", user: user, cycle: cycle, collection_days: [day])
  end
end

# 複数曜日、毎週のseed
cycle = Cycle.find(1)
(1..3).each do |num|
  day = CollectionDay.find([num, (8 - num)])
  Trash.create!(name: "#{day_str[num]}・#{day_str[(8 - num)]}曜日のゴミ", user: user, cycle: cycle, collection_days: day)

  day = CollectionDay.find([num, (7 - num)])
  Trash.create!(name: "#{day_str[num]}・#{day_str[(7 - num)]}曜日のゴミ", user: user, cycle: cycle, collection_days: day)
end
