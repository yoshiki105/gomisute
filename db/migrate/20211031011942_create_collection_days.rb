class CreateCollectionDays < ActiveRecord::Migration[6.1]
  def change
    create_table :collection_days do |t|
      t.integer :day_of_week
      t.references :trash, null: false, foreign_key: true

      t.timestamps
    end
  end
end
