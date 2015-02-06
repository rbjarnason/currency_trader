class TradingPosition < ActiveRecord::Base
  belongs_to :trading_operation
  belongs_to :trading_strategy
  belongs_to :trading_signal

  default_scope { where("profit_loss IS NOT NULL AND value_open != 0.0 AND value_close != 0.0 AND updated_at BETWEEN '2014-03-01 14:15:55' AND '2014-12-01 00:15:55'") }

end
