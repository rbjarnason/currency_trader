class CreateTradingStrategyPopulations < ActiveRecord::Migration
  def change
    create_table :trading_strategy_populations do |t|
      t.integer "quote_target_id"
      t.timestamps
    end
  end
end