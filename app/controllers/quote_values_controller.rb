class QuoteValuesController < ApplicationController
  layout "main"

  # GET /quote_values
  # GET /quote_values.xml
  def index
    @quote_values = QuoteValue.find(:all, :order=>"quote_target_id ASC, data_time ASC", :limit=>250)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @quote_values }
    end
  end

  # GET /quote_values/1
  # GET /quote_values/1.xml
  def show
    @quote_value = QuoteValue.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @quote_value }
    end
  end

  # GET /quote_values/new
  # GET /quote_values/new.xml
  def new
    @quote_value = QuoteValue.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @quote_value }
    end
  end

  # GET /quote_values/1/edit
  def edit
    @quote_value = QuoteValue.find(params[:id])
  end

  # POST /quote_values
  # POST /quote_values.xml
  def create
    @quote_value = QuoteValue.new(params[:quote_value])

    respond_to do |format|
      if @quote_value.save
        flash[:notice] = 'QuoteValue was successfully created.'
        format.html { redirect_to(@quote_value) }
        format.xml  { render :xml => @quote_value, :status => :created, :location => @quote_value }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @quote_value.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /quote_values/1
  # PUT /quote_values/1.xml
  def update
    @quote_value = QuoteValue.find(params[:id])

    respond_to do |format|
      if @quote_value.update_attributes(params[:quote_value])
        flash[:notice] = 'QuoteValue was successfully updated.'
        format.html { redirect_to(@quote_value) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @quote_value.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /quote_values/1
  # DELETE /quote_values/1.xml
  def destroy
    @quote_value = QuoteValue.find(params[:id])
    @quote_value.destroy

    respond_to do |format|
      format.html { redirect_to(quote_values_url) }
      format.xml  { head :ok }
    end
  end
end
