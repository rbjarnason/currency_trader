class AddOptmiz < ActiveRecord::Migration
  def up
    add_column :trading_strategies, :trading_strategy_population_id, :integer
    add_column :trading_strategies, :no_delete, :boolean, :default=>false
    add_column :trading_strategy_sets, :no_delete, :boolean, :default=>false

    add_index :trading_strategy_sets, [:no_delete, :trading_strategy_population_id], :name=>"nodel_trad_set_pop_id"
    add_index :trading_strategies, [:no_delete, :trading_strategy_population_id], :name=>"nodel_trad_pop_id"
    add_index :trading_strategies, :trading_strategy_population_id
  end

  def down
  end
end
