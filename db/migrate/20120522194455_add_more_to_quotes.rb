class AddMoreToQuotes < ActiveRecord::Migration
  def change
    add_column :quote_values, :bid, :float
    add_column :quote_values, :offer, :float
  end
end
