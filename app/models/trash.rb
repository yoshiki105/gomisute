class Trash < ApplicationRecord
  belongs_to :user
  belongs_to :collection_day
  belongs_to :cycle

  def latest_collection_day
    collection_days.order(created_at: :desc).first
  end

  def is_thrown_away?(day)
    collection_days.where(day_of_week: day).present?
  end
end
