class AddMoreIndexes < ActiveRecord::Migration
  def up


    add_index :quote_values, :created_at
    add_index :quote_values, :data_time
  end

  def down
  end
end
