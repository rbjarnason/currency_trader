class AddTsToTp < ActiveRecord::Migration
  def change
    add_column :trading_positions, :trading_signal_id, :integer
  end
end
