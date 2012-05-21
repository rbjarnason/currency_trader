class TradingSignal < ActiveRecord::Base
  belongs_to :trading_position
  belongs_to :trading_operation
  belongs_to :trading_strategy

  def position
    self.trading_position
  end
end
