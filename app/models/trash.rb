class Trash < ApplicationRecord
  belongs_to :user
  has_many :collection_days, dependent: :destroy

  def latest_collection_day
    collection_days.order(created_at: :desc).first
  end
end
