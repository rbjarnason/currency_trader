class StopLoss < ActiveRecord::Migration
  def up
    add_column :trading_strategy_populations, :stop_loss_enabled, :boolean, :default=>false
    add_column :trading_strategies, :current_stop_loss_until, :datetime
    add_column :trading_strategies, :last_stop_loss_until, :datetime
  end

  def down
  end
end
