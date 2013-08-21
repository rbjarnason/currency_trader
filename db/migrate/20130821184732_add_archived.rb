class AddArchived < ActiveRecord::Migration
  def up
    add_column :trading_strategy_sets, :archived, :boolean, :default=>false
  end

  def down
  end
end
