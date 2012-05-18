class RemoveFitness < ActiveRecord::Migration
  def up
    remove_column :trading_strategies, :fitness
    add_column :trading_strategies, :simulated_fitness, :float
  end

  def down
  end
end
