class CreateCycles < ActiveRecord::Migration[6.1]
  def change
    create_table :cycles do |t|
      t.references :trash, null: false, foreign_key: true
      t.integer :name, null: false

      t.timestamps
    end
  end
end
