class TradingTimeFramesController < ApplicationController
  # GET /trading_time_frames
  # GET /trading_time_frames.json
  def index
    @trading_time_frames = TradingTimeFrame.all

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @trading_time_frames }
    end
  end

  # GET /trading_time_frames/1
  # GET /trading_time_frames/1.json
  def show
    @trading_time_frame = TradingTimeFrame.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trading_time_frame }
    end
  end

  # GET /trading_time_frames/new
  # GET /trading_time_frames/new.json
  def new
    @trading_time_frame = TradingTimeFrame.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trading_time_frame }
    end
  end

  # GET /trading_time_frames/1/edit
  def edit
    @trading_time_frame = TradingTimeFrame.find(params[:id])
  end

  # POST /trading_time_frames
  # POST /trading_time_frames.json
  def create
    @trading_time_frame = TradingTimeFrame.new(params[:trading_time_frame])

    respond_to do |format|
      if @trading_time_frame.save
        format.html { redirect_to @trading_time_frame, notice: 'Trading time frame was successfully created.' }
        format.json { render json: @trading_time_frame, status: :created, location: @trading_time_frame }
      else
        format.html { render action: "new" }
        format.json { render json: @trading_time_frame.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trading_time_frames/1
  # PUT /trading_time_frames/1.json
  def update
    @trading_time_frame = TradingTimeFrame.find(params[:id])

    respond_to do |format|
      if @trading_time_frame.update_attributes(params[:trading_time_frame])
        format.html { redirect_to @trading_time_frame, notice: 'Trading time frame was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trading_time_frame.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trading_time_frames/1
  # DELETE /trading_time_frames/1.json
  def destroy
    @trading_time_frame = TradingTimeFrame.find(params[:id])
    @trading_time_frame.destroy

    respond_to do |format|
      format.html { redirect_to trading_time_frames_url }
      format.json { head :no_content }
    end
  end
end
