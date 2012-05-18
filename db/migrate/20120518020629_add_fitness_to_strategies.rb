class AddFitnessToStrategies < ActiveRecord::Migration
  def change
    add_column :trading_strategies, :fitness, :float
  end
end
