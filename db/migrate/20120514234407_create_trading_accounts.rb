class CreateTradingAccounts < ActiveRecord::Migration
  def change
    create_table :trading_accounts do |t|
      t.string "name"
      t.timestamps
    end
  end
end
