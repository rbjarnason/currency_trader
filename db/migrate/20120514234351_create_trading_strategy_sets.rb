class CreateTradingStrategySets < ActiveRecord::Migration
  def change
    create_table :trading_strategy_sets do |t|
      t.string   "name"
      t.integer  "how_many_strategies"
      t.integer  "trading_time_frame_id"
      t.float    "fitness_score"
      t.timestamps
    end
  end
end