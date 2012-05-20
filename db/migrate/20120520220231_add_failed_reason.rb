class AddFailedReason < ActiveRecord::Migration
  def up
    add_column :trading_strategies, :simulated_fitness_failure_reason, :string
  end

  def down
  end
end
