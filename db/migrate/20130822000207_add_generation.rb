class AddGeneration < ActiveRecord::Migration
  def up
    add_column :trading_strategy_sets, :generation, :integer, :null=>false
    add_index "trading_strategy_sets", ["generation", "complete","error_flag"], :name => "generation_trad_set_pop_id"
  end

  def down
  end
end
