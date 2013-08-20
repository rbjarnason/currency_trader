class TradingPosition
  include Mongoid::Document
  include Mongoid::Timestamps
  index({ open: 1 }, { unique: false, name: "trading_strategy_set_id_index" })

  belongs_to :trading_strategy
  belongs_to :trading_operation
  has_one :trading_signal

  field :open, type: Boolean, default: true

  field :value_open, type: Float
  field :value_close, type: Float
  field :profit_loss, type: Float
  field :units, type: Integer


end
