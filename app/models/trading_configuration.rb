class TradingConfiguration
  include Mongoid::Document

  field :run_evolution, type: Boolean, default: true

  def self.stop_evolution
    config = TradingConfiguration.new unless config = TradingConfiguration.first
    config.run_evolution = false
    config.save
  end

  def self.start_evolution
    config = TradingConfiguration.new unless config = TradingConfiguration.first
    config.run_evolution = true
    config.save
  end

  def self.can_evolve?
    unless config = TradingConfiguration.first
      config = TradingConfiguration.new
      config.save
    end
    config.run_evolution
  end
end