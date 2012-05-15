class CreateTradingEvolutions < ActiveRecord::Migration
  def change
    create_table :trading_evolutions do |t|
      t.integer "quote_target_id"
      t.timestamps
    end

    create_table "trading_evolutions_trading_strategies_sets", :force => true, :id=>false do |t|
      t.integer  "trading_evolution_id"
      t.integer  "trading_strategy_set_id"
    end
  end
end