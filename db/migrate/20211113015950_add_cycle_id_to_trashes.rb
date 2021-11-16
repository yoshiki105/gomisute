class AddCycleIdToTrashes < ActiveRecord::Migration[6.1]
  def change
    add_reference :trashes, :cycle, null: false, foreign_key: true
  end
end
