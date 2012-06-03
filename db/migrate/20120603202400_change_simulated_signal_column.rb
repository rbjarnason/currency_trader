class ChangeSimulatedSignalColumn < ActiveRecord::Migration
  def up
    change_column :trading_strategies, :simulated_trading_signals, :binary
  end

  def down
  end
end
