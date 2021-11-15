class Trash < ApplicationRecord
  belongs_to :user
  belongs_to :cycle
  has_many :trash_collection_days
  has_many :collection_days, through: :trash_collection_days

  scope :with_collection_days, -> { joins(:collection_days) }
  scope :with_cycle, -> { joins(:cycle) }
  scope :search_with_youbi, ->(youbi) { where(collection_days: { day_of_week: youbi }) }
  scope :search_with_cycle, ->(cycle) { where(cycles: { name: cycle }) }
  scope :search_with_user, ->(user) { where(user_id: user.id) }
  scope :throw_away, -> (nansyu, youbi) do
    # 隔週は一旦無し
    searching_cycles = case nansyu
    when 1, 3
      [:every_week, :first_and_third]
    when 2, 4
      [:every_week, :second_and_fourth]
    else
      :every_week
    end

    with_collection_days.search_with_youbi(youbi).with_cycle.search_with_cycle(searching_cycles)
  end

  def latest_collection_day
    collection_days.order(created_at: :desc).first
  end

  def is_thrown_away?(day)
    collection_days.where(day_of_week: day).present?
  end
end
