class AddToPopulation < ActiveRecord::Migration
  def up
    add_column :trading_strategies, :initial_simulation_capital, :float
    add_column :trading_strategies, :current_simulation_capital, :float
    add_column :trading_strategies, :number_of_evolution_trading_signals, :integer, :default=>0

    remove_column :trading_strategies, :parameters
    add_column :trading_strategies, :binary_parameters, :text
    add_column :trading_strategies, :float_parameters, :text

    add_column :trading_time_frames, :from_hour, :integer
    add_column :trading_time_frames, :to_hour, :integer

    add_column :trading_strategy_sets, :complete, :boolean, :default=>false
    add_column :trading_strategy_sets, :error_flag, :boolean, :default=>false
    add_column :trading_strategy_sets, :active, :boolean, :default=>false
    add_column :trading_strategy_sets, :in_population_process, :boolean, :default=>false
    add_column :trading_strategy_sets, :in_process, :boolean, :default=>false
    add_column :trading_strategy_sets, :last_processing_start_time, :datetime
    add_column :trading_strategy_sets, :last_processing_stop_time, :datetime
    add_column :trading_strategy_sets, :last_work_unit_time, :datetime
    add_column :trading_strategy_sets, :processing_time_interval, :integer, :default => 1800

    add_column :trading_strategy_populations, :complete, :boolean, :default=>false
    add_column :trading_strategy_populations, :active, :boolean, :default=>false
    add_column :trading_strategy_populations, :in_process, :boolean, :default=>false
    add_column :trading_strategy_populations, :current_generation, :integer, :default=>0
    add_column :trading_strategy_populations, :max_generations, :integer
    add_column :trading_strategy_populations, :population_size, :integer
    add_column :trading_strategy_populations, :best_fitness, :float
    add_column :trading_strategy_populations, :last_processing_start_time, :datetime
    add_column :trading_strategy_populations, :last_processing_stop_time, :datetime
    add_column :trading_strategy_populations, :best_trading_strategy_set_id, :integer

    add_column :trading_strategy_populations, :population_data, :binary, :limit => 2147483647
  end

  def down
  end
end
