class AddCloseTimeout < ActiveRecord::Migration
  def up
    rename_column :trading_strategies, :how_far_back_milliseconds, :open_how_far_back_milliseconds
    add_column :trading_strategies, :close_how_far_back_milliseconds, :integer, :default=>5
  end

  def down
  end
end
