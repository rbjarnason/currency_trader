class TradingSignal
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :trading_position
  belongs_to :trading_strategy

  field :open_quote_value, type: Float
  field :close_quote_value, type: Float
  field :profit_loss, type: Float

  field :trading_operation_id, type: Integer
  field :name, type: String
  field :complete, type: Boolean, default: false

  field :debug_information, type: Moped::BSON::Binary
  field :reason, type: Moped::BSON::Binary

  def position
    self.trading_position
  end

  def trading_operation
    TradingOperation.where(:id=>self.trading_operation_id)
  end
end