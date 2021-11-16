class CreateTrashCollectionDays < ActiveRecord::Migration[6.1]
  def change
    create_table :trash_collection_days do |t|
      t.references :trash, null: false, foreign_key: true
      t.references :collection_day, null: false, foreign_key: true

      t.timestamps
    end
  end
end
