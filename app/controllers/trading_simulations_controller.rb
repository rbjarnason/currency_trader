class TradingSimulationsController < ApplicationController
  # GET /trading_simulations
  # GET /trading_simulations.json
  def index
    @trading_simulations = TradingSimulation.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @trading_simulations }
    end
  end

  # GET /trading_simulations/1
  # GET /trading_simulations/1.json
  def show
    @trading_simulation = TradingSimulation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trading_simulation }
    end
  end

  # GET /trading_simulations/new
  # GET /trading_simulations/new.json
  def new
    @trading_simulation = TradingSimulation.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trading_simulation }
    end
  end

  # GET /trading_simulations/1/edit
  def edit
    @trading_simulation = TradingSimulation.find(params[:id])
  end

  # POST /trading_simulations
  # POST /trading_simulations.json
  def create
    @trading_simulation = TradingSimulation.new(params[:trading_simulation])

    respond_to do |format|
      if @trading_simulation.save
        format.html { redirect_to @trading_simulation, notice: 'Trading simulation was successfully created.' }
        format.json { render json: @trading_simulation, status: :created, location: @trading_simulation }
      else
        format.html { render action: "new" }
        format.json { render json: @trading_simulation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trading_simulations/1
  # PUT /trading_simulations/1.json
  def update
    @trading_simulation = TradingSimulation.find(params[:id])

    respond_to do |format|
      if @trading_simulation.update_attributes(params[:trading_simulation])
        format.html { redirect_to @trading_simulation, notice: 'Trading simulation was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trading_simulation.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trading_simulations/1
  # DELETE /trading_simulations/1.json
  def destroy
    @trading_simulation = TradingSimulation.find(params[:id])
    @trading_simulation.destroy

    respond_to do |format|
      format.html { redirect_to trading_simulations_url }
      format.json { head :no_content }
    end
  end
end
