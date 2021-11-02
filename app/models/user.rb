class User < ApplicationRecord
  has_many :trashes, dependent: :destroy

  enum mode: {
    top: 0,
    registration: 1,
    show_all: 2,
    edit: 3,
    show_next: 4,
    add_day_of_week: 5,
    add_cycle: 6,
  }

end
