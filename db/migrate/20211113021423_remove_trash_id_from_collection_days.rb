class RemoveTrashIdFromCollectionDays < ActiveRecord::Migration[6.1]
  def change
    remove_reference :collection_days, :trash, null: false, foreign_key: true
  end
end
