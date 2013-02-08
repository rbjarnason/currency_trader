class TradingTimeFrame
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :trading_strategy_set

  field :time_frame, type: String
  field :from_hour, type: Integer
  field :to_hour, type: Integer

end
