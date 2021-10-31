class Trash < ApplicationRecord
  belongs_to :user
  has_many :collection_days, dependent: :destroy
end
