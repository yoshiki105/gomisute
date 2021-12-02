class RenameModeColumnToUsers < ActiveRecord::Migration[6.1]
  def change
    rename_column :users, :mode, :status
  end
end
