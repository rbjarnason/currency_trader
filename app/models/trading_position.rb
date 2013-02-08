class TradingPosition < ActiveRecord::Base
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :trading_strategy
  field :trading_operation_id, type: Integer

  field :open, type: Boolean, default: true

  field :value_open, type: Float
  field :value_close, type: Float
  field :profit_loss, type: Float
  field :units, type: Integer

  def trading_operation
    TradingOperation.where(:id=>self.trading_operation_id)
  end
end
