class CreateTradingStrategies < ActiveRecord::Migration
  def change
    create_table :trading_strategies do |t|
      t.string   "name"
      t.text     "strategy"
      t.integer  "how_many_days_back"
      t.timestamps
    end

    create_table "trading_strategies_trading_strategies_sets", :force => true, :id=>false do |t|
      t.integer  "trading_strategy_id"
      t.integer  "trading_strategy_set_id"
    end
  end
end
