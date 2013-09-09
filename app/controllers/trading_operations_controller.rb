class TradingOperationsController < ApplicationController
  def show_all_for
    @operation = TradingOperation.find(params[:id])
    @current_day = params[:current_day] ? Date.parse(params[:current_day]) : Date.today
  end

  def index
    @trading_operations = TradingOperation.where("active = 1").order("id DESC").all
  end

  def chart
    @operation = TradingOperation.find(params[:id])
    @day_offset = params[:day_offset]
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @operation }
    end
  end

  def set_state
    @operation = TradingOperation.find(params[:id])
    state = params[:state]
    if state=="pause" and not @operation.paused?
      @operation.pause!
    elsif state=="long" and not @operation.long?
      @operation.long!
    elsif state=="short" and not @operation.short?
      @operation.short!
    elsif state=="automatic" and not @operation.automatic?
      @operation.automatic!
    end
    redirect_to :back
  end

end
