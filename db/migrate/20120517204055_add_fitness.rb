class AddFitness < ActiveRecord::Migration
  def up
    add_column :trading_strategy_sets, :accumulated_fitness, :float
  end

  def down
  end
end
