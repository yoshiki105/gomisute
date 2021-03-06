class Trash < ApplicationRecord
  belongs_to :user
  belongs_to :cycle
  has_one :notification, dependent: :destroy
  has_many :trash_collection_days, dependent: :destroy
  has_many :collection_days, through: :trash_collection_days

  scope :with_collection_days, -> { joins(:collection_days) }
  scope :with_cycle, -> { joins(:cycle) }
  scope :with_notification, -> { joins(:notification) }
  scope :search_with_youbi, ->(youbi) { where(collection_days: { day_of_week: youbi }) }
  scope :search_with_cycle, ->(cycle) { where(cycles: { name: cycle }) }
  scope :search_with_user, ->(user) { where(user_id: user.id) }
  scope :search_with_notify_at, ->(notify_at) { where(notification: { notify_at: notify_at }) }
  scope :throw_away, lambda { |nansyu, youbi, now_at|
    searching_cycles = case nansyu
                       when 1, 3
                         %i[every_week first_and_third]
                       when 2, 4
                         %i[every_week second_and_fourth]
                       else
                         [:every_week]
                       end
    ## 隔週のゴミを追加する
    # 今日の週番号
    now_week_num = Time.zone.today.strftime('%W').to_i
    # 奇数ならodd_weeksを、そうでないならeven_weeksを追加する
    searching_cycles << (now_week_num.even? ? :even_weeks : :odd_weeks)

    with_collection_days.search_with_youbi(youbi)
                        .with_cycle
                        .search_with_cycle(searching_cycles)
                        .with_notification
                        .search_with_notify_at(now_at)
  }

  def collection_days_list
    collection_days.map(&:day_of_week_i18n).join('・')
  end

  def thrown_away?(day)
    collection_days.where(day_of_week: day).present?
  end
end
