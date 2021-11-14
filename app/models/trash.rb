class Trash < ApplicationRecord
  belongs_to :user
  belongs_to :cycle
  has_many :trash_collection_days
  has_many :collection_days, through: :trash_collection_days

  def latest_collection_day
    collection_days.order(created_at: :desc).first
  end

  def is_thrown_away?(day)
    collection_days.where(day_of_week: day).present?
  end
end
