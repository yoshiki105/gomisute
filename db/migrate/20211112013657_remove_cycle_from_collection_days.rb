class RemoveCycleFromCollectionDays < ActiveRecord::Migration[6.1]
  def change
    remove_column :collection_days, :cycle, :integer
  end
end
