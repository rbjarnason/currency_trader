class AddSimulatedSignals < ActiveRecord::Migration
  def up
    add_column :trading_strategies, :simulated_trading_signals, :text
    add_column :trading_strategies, :simulated_start_date, :datetime
    add_column :trading_strategies, :simulated_end_date, :datetime
  end

  def down
  end
end
