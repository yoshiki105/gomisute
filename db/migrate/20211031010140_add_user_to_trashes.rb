class AddUserToTrashes < ActiveRecord::Migration[6.1]
  def change
    add_reference :trashes, :user, null: false, foreign_key: true
  end
end
