class AddMoreToPop < ActiveRecord::Migration
  def change
    add_column :trading_strategy_populations, :simulation_max_overall_trading_signals, :integer
  end
end
