class CollectionDay < ApplicationRecord
  belongs_to :trash

  enum day_of_week: {
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
    sunday: 7,
  }

  enum cycle: {
    every_week: 1, # 毎週
    every_other_week: 2, # 隔週
    first_and_third: 3, # 第一・三
    second_and_fourth: 4, # 第二・四
  }

  def user
    trash.user
  end
end
