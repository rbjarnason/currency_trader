class TradingOperationsController < ApplicationController
  def show_all_for
    @operation = TradingOperation.find(params[:id])
    @current_day = params[:current_day] ? Date.parse(params[:current_day]) : Date.today
  end

  def chart
    @operation = TradingOperation.find(params[:id])
    @day_offset = params[:day_offset]
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @operation }
    end
  end

end
