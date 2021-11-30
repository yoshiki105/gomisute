class CreateNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :notifications do |t|
      t.belongs_to :trash, index: { unique: true }, foreign_key: true
      t.time :notify_at, null: false

      t.timestamps
    end
  end
end
