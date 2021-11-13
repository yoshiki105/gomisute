class Cycle < ApplicationRecord
  has_one :trash

  enum name: {
    every_week: 1, # 毎週
    first_and_third: 2, # 第1・3
    second_and_fourth: 3, # 第2・4
  }
end
