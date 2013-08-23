class AddInvestedAmountToPos < ActiveRecord::Migration
  def change
    add_column :trading_positions, :bought_amount, :float
    add_column :trading_positions, :sold_amount, :float
  end
end
