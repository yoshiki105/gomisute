class CreateTrashes < ActiveRecord::Migration[6.1]
  def change
    create_table :trashes do |t|
      t.string :name

      t.timestamps
    end
  end
end
