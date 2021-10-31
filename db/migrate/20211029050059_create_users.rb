class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :line_id, null: false
      t.integer :mode, null: false, default: 0

      t.timestamps
    end
  end
end
