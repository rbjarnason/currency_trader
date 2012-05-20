class AddToPop < ActiveRecord::Migration
  def up
    add_column :trading_strategy_populations, :simulation_number_of_trading_strategies_per_set, :integer
    add_column :trading_strategy_populations, :simulation_days_back, :integer
    add_column :trading_strategy_populations, :simulation_end_date, :datetime
    add_column :trading_strategy_populations, :simulation_min_overall_trading_signals, :integer
    add_column :trading_strategy_populations, :simulation_max_daily_trading_signals, :integer
    add_column :trading_strategy_populations, :simulation_max_minutes_back, :integer
  end

  def down
  end
end
