class TradingStrategyPopulationsController < ApplicationController
  def show_all_for
    @population = TradingStrategyPopulation.find(params[:id])
  end

  def index
    @trading_strategy_populations = TradingStrategyPopulation.order("active desc").all
  end

  def deactivate
    @population = TradingStrategyPopulation.where(:id=>params[:id]).lock(:true).first
    @population.active = false
    @population.save
    redirect_to :back
  end

  def activate
    @population = TradingStrategyPopulation.where(:id=>params[:id]).lock(:true).first
    @population.active = true
    @population.save
    redirect_to :back
  end

end
