class TradingPosition < ActiveRecord::Base
  belongs_to :trading_operation
  belongs_to :trading_strategy
  belongs_to :trading_signal

end
