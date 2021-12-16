class AddIndexToCycleAndCollectionDay < ActiveRecord::Migration[6.1]
  def change
    add_index :cycles, :name, :unique => true
    add_index :collection_days, :day_of_week, :unique => true
  end
end
