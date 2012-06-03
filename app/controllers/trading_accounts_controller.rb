class TradingAccountsController < ApplicationController
  # GET /trading_accounts
  # GET /trading_accounts.json
  def index
    @trading_accounts = TradingAccount.all

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @trading_accounts }
    end
  end

  # GET /trading_accounts/1
  # GET /trading_accounts/1.json
  def show
    @trading_account = TradingAccount.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @trading_account }
    end
  end

  # GET /trading_accounts/new
  # GET /trading_accounts/new.json
  def new
    @trading_account = TradingAccount.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @trading_account }
    end
  end

  # GET /trading_accounts/1/edit
  def edit
    @trading_account = TradingAccount.find(params[:id])
  end

  # POST /trading_accounts
  # POST /trading_accounts.json
  def create
    @trading_account = TradingAccount.new(params[:trading_account])

    respond_to do |format|
      if @trading_account.save
        format.html { redirect_to @trading_account, notice: 'Trading account was successfully created.' }
        format.json { render json: @trading_account, status: :created, location: @trading_account }
      else
        format.html { render action: "new" }
        format.json { render json: @trading_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /trading_accounts/1
  # PUT /trading_accounts/1.json
  def update
    @trading_account = TradingAccount.find(params[:id])

    respond_to do |format|
      if @trading_account.update_attributes(params[:trading_account])
        format.html { redirect_to @trading_account, notice: 'Trading account was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @trading_account.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /trading_accounts/1
  # DELETE /trading_accounts/1.json
  def destroy
    @trading_account = TradingAccount.find(params[:id])
    @trading_account.destroy

    respond_to do |format|
      format.html { redirect_to trading_accounts_url }
      format.json { head :no_content }
    end
  end
end
