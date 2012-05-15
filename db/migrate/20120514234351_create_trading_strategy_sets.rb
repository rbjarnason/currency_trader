class CreateTradingStrategySets < ActiveRecord::Migration
  def change
    create_table :trading_strategy_sets do |t|
      t.integer  "trading_strategy_population_id", :null=>false
      t.integer  "trading_time_frame_id", :null=>false
      t.text     "parameters"
      t.float    "fitness_score"
      t.timestamps
    end

    create_table :trading_strategy_signals do |t|
      t.integer  "trading_strategy_id", :null=>false
      t.float     "signal", :null=>false
      t.timestamps
    end
  end
end