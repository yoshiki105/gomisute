class CollectionDay < ApplicationRecord
  has_many :trashes

  enum day_of_week: {
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
    sunday: 7,
  }

  def user
    trash.user
  end
end
