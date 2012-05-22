class AddToQuoteValues < ActiveRecord::Migration
  def up
    add_column :quote_values, :timestamp_ms, :integer
    add_column :quote_values, :bid_big_figure, :float
    add_column :quote_values, :bid_points, :float
    add_column :quote_values, :offer_big_figure, :float
    add_column :quote_values, :offer_points, :float
    add_column :quote_values, :high, :float
    add_column :quote_values, :low, :float
    add_column :quote_values, :open, :float
  end

  def down
  end
end
