class AddSignalsMore < ActiveRecord::Migration
  def up
    add_column :trading_signals, :open_quote_value, :float
    add_column :trading_signals, :close_quote_value, :float
    add_column :trading_signals, :profit_loss, :float
    add_column :trading_signals, :trading_position_id, :integer
    add_column :trading_signals, :trading_operation_id, :integer
    remove_column :trading_signals, :signal
    add_column :trading_signals, :name, :string
    add_column :trading_signals, :debug_information, :text

    remove_column :trading_operations, :current_capital_amount
    add_column :trading_operations, :current_capital, :float

    create_table "trading_positions", :force => true do |t|
      t.integer  "trading_operation_id",     :null => false
      t.integer  "trading_strategy_id",     :null => false
      t.boolean   "open",                  :default => true
      t.float    "value_open"
      t.float    "value_close"
      t.integer  "units"
      t.datetime "created_at",             :null => false
      t.datetime "updated_at",             :null => false
    end
  end

  def down
  end
end
