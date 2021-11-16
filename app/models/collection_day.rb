class CollectionDay < ApplicationRecord
  has_many :trash_collection_days
  has_many :trashes, through: :trash_collection_days

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
