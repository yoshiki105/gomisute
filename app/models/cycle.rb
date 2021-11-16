class Cycle < ApplicationRecord
  has_one :trash, dependent: :destroy

  enum name: {
    every_week: 1, # 毎週
    odd_weeks: 2, # 奇数週
    even_weeks: 3, # 偶数週
    first_and_third: 4, # 第1・3
    second_and_fourth: 5 # 第2・4
  }
end
