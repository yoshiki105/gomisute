class AddCollectionDayIdToTrash < ActiveRecord::Migration[6.1]
  def change
    add_reference :trashes, :collection_day, null: false, foreign_key: true
  end
end
