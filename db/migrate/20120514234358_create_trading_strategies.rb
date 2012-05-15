class CreateTradingStrategies < ActiveRecord::Migration
  def change
    create_table :trading_strategy_templates do |t|
      t.string   "name", :null=>false
      t.text     "code", :null=>false
      t.timestamps
    end

    create_table :trading_strategies do |t|
      t.integer  "trading_strategy_template_id", :null=>false
      t.integer  "trading_strategy_set_id", :null=>false
      t.text     "parameters"
      t.timestamps
    end

  end
end
