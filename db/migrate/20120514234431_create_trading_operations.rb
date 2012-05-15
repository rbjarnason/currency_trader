class CreateTradingOperations < ActiveRecord::Migration
  def change
    create_table :trading_operations do |t|
      t.integer "quote_target_id", :null=>false
      t.integer "trading_account_id", :null=>false
      t.float   "initial_capital_amount", :null=>false
      t.float   "current_capital_amount", :null=>false
      t.timestamps
    end
  end
end
