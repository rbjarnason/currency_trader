class CreateTradingSimulations < ActiveRecord::Migration
  def change
    create_table :trading_simulations do |t|
      t.integer "quote_target_id"
      t.integer "trading_account_id"
      t.timestamps
    end
  end
end
