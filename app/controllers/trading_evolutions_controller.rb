class TradingEvolutionsController < ApplicationController
  # GET /trading_evolutions
  # GET /trading_evolutions.json
  def index
    @trading_evolutions = TradingEvolution.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trading_evolutions }
    end
  end

  # GET /trading_evolutions/1
  # GET /trading_evolutions/1.json
  def show
    @trading_evolution = TradingEvolution.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trading_evolution }
    end
  end

  # GET /trading_evolutions/new
  # GET /trading_evolutions/new.json
  def new
    @trading_evolution = TradingEvolution.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trading_evolution }
    end
  end

  # GET /trading_evolutions/1/edit
  def edit
    @trading_evolution = TradingEvolution.find(params[:id])
  end

  # POST /trading_evolutions
  # POST /trading_evolutions.json
  def create
    @trading_evolution = TradingEvolution.new(params[:trading_evolution])

    respond_to do |format|
      if @trading_evolution.save
        format.html { redirect_to @trading_evolution, notice: 'Trading evolution was successfully created.' }
        format.json { render json: @trading_evolution, status: :created, location: @trading_evolution }
      else
        format.html { render action: "new" }
        format.json { render json: @trading_evolution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trading_evolutions/1
  # PUT /trading_evolutions/1.json
  def update
    @trading_evolution = TradingEvolution.find(params[:id])

    respond_to do |format|
      if @trading_evolution.update_attributes(params[:trading_evolution])
        format.html { redirect_to @trading_evolution, notice: 'Trading evolution was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trading_evolution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trading_evolutions/1
  # DELETE /trading_evolutions/1.json
  def destroy
    @trading_evolution = TradingEvolution.find(params[:id])
    @trading_evolution.destroy

    respond_to do |format|
      format.html { redirect_to trading_evolutions_url }
      format.json { head :no_content }
    end
  end
end
