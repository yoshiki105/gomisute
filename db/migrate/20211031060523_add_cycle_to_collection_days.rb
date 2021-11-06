class AddCycleToCollectionDays < ActiveRecord::Migration[6.1]
  def change
    add_column :collection_days, :cycle, :integer
  end
end
