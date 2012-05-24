class AddReason < ActiveRecord::Migration
  def up
    add_column :trading_signals, :reason, :text
  end

  def down
  end
end
