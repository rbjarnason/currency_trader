class AddArchivedIndex < ActiveRecord::Migration
  def up
    add_index "trading_strategy_sets", ["archived", "trading_strategy_population_id"], :name => "archived_trad_set_pop_id"
  end

  def down
  end
end
