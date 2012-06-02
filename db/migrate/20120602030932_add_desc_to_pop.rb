class AddDescToPop < ActiveRecord::Migration
  def change
    add_column :trading_strategy_populations, :description, :text
  end
end
