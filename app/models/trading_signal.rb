class TradingSignal < ActiveRecord::Base
  belongs_to :trading_position
  belongs_to :trading_operation
  belongs_to :trading_strategy

  default_scope { where("close_quote_value != 0 OR open_quote_value != 0") }

  def position
    self.trading_position
  end
end
