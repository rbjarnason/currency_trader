class AddToStart < ActiveRecord::Migration
  def up
    add_column :trading_strategies, :open_how_far_back_milliseconds, :integer
  end

  def down
  end
end
