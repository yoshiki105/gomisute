class RemoveTrashIdFromCycles < ActiveRecord::Migration[6.1]
  def change
    remove_reference :cycles, :trash, null: false, foreign_key: true
  end
end
