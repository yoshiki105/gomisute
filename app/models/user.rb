class User < ApplicationRecord
  has_many :trashes, dependent: :destroy

end
