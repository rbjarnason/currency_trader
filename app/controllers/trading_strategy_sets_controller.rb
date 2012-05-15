class TradingStrategySetsController < ApplicationController
  # GET /trading_strategy_sets
  # GET /trading_strategy_sets.json
  def index
    @trading_strategy_sets = TradingStrategySet.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trading_strategy_sets }
    end
  end

  # GET /trading_strategy_sets/1
  # GET /trading_strategy_sets/1.json
  def show
    @trading_strategy_set = TradingStrategySet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trading_strategy_set }
    end
  end

  # GET /trading_strategy_sets/new
  # GET /trading_strategy_sets/new.json
  def new
    @trading_strategy_set = TradingStrategySet.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trading_strategy_set }
    end
  end

  # GET /trading_strategy_sets/1/edit
  def edit
    @trading_strategy_set = TradingStrategySet.find(params[:id])
  end

  # POST /trading_strategy_sets
  # POST /trading_strategy_sets.json
  def create
    @trading_strategy_set = TradingStrategySet.new(params[:trading_strategy_set])

    respond_to do |format|
      if @trading_strategy_set.save
        format.html { redirect_to @trading_strategy_set, notice: 'Trading strategy set was successfully created.' }
        format.json { render json: @trading_strategy_set, status: :created, location: @trading_strategy_set }
      else
        format.html { render action: "new" }
        format.json { render json: @trading_strategy_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trading_strategy_sets/1
  # PUT /trading_strategy_sets/1.json
  def update
    @trading_strategy_set = TradingStrategySet.find(params[:id])

    respond_to do |format|
      if @trading_strategy_set.update_attributes(params[:trading_strategy_set])
        format.html { redirect_to @trading_strategy_set, notice: 'Trading strategy set was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trading_strategy_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trading_strategy_sets/1
  # DELETE /trading_strategy_sets/1.json
  def destroy
    @trading_strategy_set = TradingStrategySet.find(params[:id])
    @trading_strategy_set.destroy

    respond_to do |format|
      format.html { redirect_to trading_strategy_sets_url }
      format.json { head :no_content }
    end
  end
end
