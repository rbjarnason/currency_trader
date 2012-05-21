class AddIndexes < ActiveRecord::Migration
  def up
    add_index :quote_targets, :symbol

    add_index :quote_values, :created_at
    add_index :quote_values, :data_time

    add_index :trading_operations, :quote_target_id

    add_index :trading_signals, :trading_strategy_id

    add_index :trading_strategies, :trading_strategy_set_id


    add_index :trading_strategy_populations, :quote_target_id

    add_index :trading_strategy_sets, :trading_strategy_population_id
    add_index :trading_strategy_sets, :trading_time_frame_id
    add_index :trading_strategy_sets, :accumulated_fitness
  end

  def down
  end
end
