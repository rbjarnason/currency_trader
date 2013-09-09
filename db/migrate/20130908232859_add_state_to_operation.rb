class AddStateToOperation < ActiveRecord::Migration
  def change
    add_column :trading_operations, :workflow_state, :string
  end
end
