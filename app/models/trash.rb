class Trash < ApplicationRecord
  belongs_to :user
  has_many :collection_days, dependent: :destroy
  has_one :cycle

  def latest_collection_day
    collection_days.order(created_at: :desc).first
  end

  def is_thrown_away?(day)
    collection_days.where(day_of_week: day).present?
  end
end
