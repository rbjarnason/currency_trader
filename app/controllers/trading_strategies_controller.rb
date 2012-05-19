class TradingStrategiesController < ApplicationController
  # GET /trading_strategies
  # GET /trading_strategies.json
  def index
    @trading_strategies = TradingStrategy.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trading_strategies }
    end
  end

  # GET /trading_strategies/1
  # GET /trading_strategies/1.json
  def show
    @trading_strategy = TradingStrategy.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trading_strategy }
    end
  end

  # GET /trading_strategies/new
  # GET /trading_strategies/new.json
  def new
    @trading_strategy = TradingStrategy.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trading_strategy }
    end
  end

  # GET /trading_strategies/1/edit
  def edit
    @trading_strategy = TradingStrategy.find(params[:id])
  end

  # POST /trading_strategies
  # POST /trading_strategies.json
  def create
    @trading_strategy = TradingStrategy.new(params[:trading_strategy])

    respond_to do |format|
      if @trading_strategy.save
        format.html { redirect_to @trading_strategy, notice: 'Trading strategy was successfully created.' }
        format.json { render json: @trading_strategy, status: :created, location: @trading_strategy }
      else
        format.html { render action: "new" }
        format.json { render json: @trading_strategy.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trading_strategies/1
  # PUT /trading_strategies/1.json
  def update
    @trading_strategy = TradingStrategy.find(params[:id])

    respond_to do |format|
      if @trading_strategy.update_attributes(params[:trading_strategy])
        format.html { redirect_to @trading_strategy, notice: 'Trading strategy was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trading_strategy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trading_strategies/1
  # DELETE /trading_strategies/1.json
  def destroy
    @trading_strategy = TradingStrategy.find(params[:id])
    @trading_strategy.destroy

    respond_to do |format|
      format.html { redirect_to trading_strategies_url }
      format.json { head :no_content }
    end
  end

  def chart
    @trading_strategy = TradingStrategy.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trading_strategy }
    end
  end
end
