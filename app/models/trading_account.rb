class TradingAccount
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::OptimisticLocking

  has_many :trading_operations

  field :name, type: String
end
