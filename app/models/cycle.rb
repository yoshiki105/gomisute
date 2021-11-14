class Cycle < ApplicationRecord
  has_one :trash

  enum name: {
    every_week: 1, # 毎週
    every_other_week: 2, # 隔週
    first_and_third: 3, # 第1・3
    second_and_fourth: 4, # 第2・4
  }
end
