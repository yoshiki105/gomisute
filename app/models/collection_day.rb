class CollectionDay < ApplicationRecord
  has_many :trash_collection_days, dependent: :destroy
  has_many :trashes, through: :trash_collection_days

  validate :day_of_week_not_changed

  enum day_of_week: {
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
    sunday: 7
  }

  delegate :user, to: :trash

  private

  def day_of_week_not_changed
    if day_of_week_changed? && self.persisted?
      errors.add(:day_of_week, "Change of day_of_week not allowed!")
    end
  end
end
