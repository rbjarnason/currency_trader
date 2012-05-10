class QuoteTargetsController < ApplicationController
  layout "main"

  def charts
    QuoteTarget.find(:all).each do |target|
      g = Gruff::Line.new(400)
      g.title = "#{target.symbol[0..2]}/#{target.symbol[4..6]}"
      values = []
      target.quote_values.each do |value|
        values << value.ask
      end
      g.data("Rate", values)
      g.write("#{Rails.root}/public/images/quote_chart_#{target.id}.png")
    end
  end

  # GET /quote_targets
  # GET /quote_targets.xml
  def index
    @quote_targets = QuoteTarget.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @quote_targets }
    end
  end

  # GET /quote_targets/1
  # GET /quote_targets/1.xml
  def show
    if params[:id]=="all"
      @quote_targets = QuoteTarget.find(:all)
    else
      @quote_target = QuoteTarget.find(params[:id])
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quote_target ? @quote_target : @quote_targets }
    end
  end

  # GET /quote_targets/new
  # GET /quote_targets/new.xml
  def new
    @quote_target = QuoteTarget.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @quote_target }
    end
  end

  # GET /quote_targets/1/edit
  def edit
    @quote_target = QuoteTarget.find(params[:id])
  end

  # POST /quote_targets
  # POST /quote_targets.xml
  def create
    @quote_target = QuoteTarget.new(params[:quote_target])
    @quote_target.last_processing_time = 0
    respond_to do |format|
      if @quote_target.save
        flash[:notice] = 'QuoteTarget was successfully created.'
        format.html { redirect_to(@quote_target) }
        format.xml  { render :xml => @quote_target, :status => :created, :location => @quote_target }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @quote_target.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quote_targets/1
  # PUT /quote_targets/1.xml
  def update
    @quote_target = QuoteTarget.find(params[:id])
    @quote_target.last_processing_time = 0
    respond_to do |format|
      if @quote_target.update_attributes(params[:quote_target])
        flash[:notice] = 'QuoteTarget was successfully updated.'
        format.html { redirect_to(@quote_target) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quote_target.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quote_targets/1
  # DELETE /quote_targets/1.xml
  def destroy
    @quote_target = QuoteTarget.find(params[:id])
    @quote_target.destroy

    respond_to do |format|
      format.html { redirect_to(quote_targets_url) }
      format.xml  { head :ok }
    end
  end
end
