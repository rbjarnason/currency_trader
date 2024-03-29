class TradingOperation < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :quote_target
  belongs_to :trading_account
  belongs_to :trading_strategy_population
  has_many :trading_positions
  has_many :trading_signals


  include Workflow

  workflow do
    state :automatic do
      event :pause, :transitions_to => :paused
      event :short, :transitions_to => :short
      event :long, :transitions_to => :long
    end
    state :long do
      event :pause, :transitions_to => :paused
      event :short, :transitions_to => :short
      event :automatic, :transitions_to => :automatic
    end
    state :short do
      event :pause, :transitions_to => :paused
      event :long, :transitions_to => :long
      event :automatic, :transitions_to => :automatic
    end
    state :paused do
      event :automatic, :transitions_to => :automatic
      event :short, :transitions_to => :short
      event :long, :transitions_to => :long
    end
  end

  def pause
    sell_everything!
  end

  def long
    #sell_everything!
  end

  def short
    #sell_everything!
  end

  def automatic
    #sell_everything!
  end

  def sell_everything!
    self.trading_positions.where(:open=>true).each do |position|
      puts position.id
      if position.trading_signal.name=="Short Open"
        close_signal_name = "Short Close"
      elsif position.trading_signal.name=="Long Open"
        close_signal_name = "Long Close"
      else
        close_signal_name = nil
      end
      if close_signal_name
        signal = TradingSignal.new
        signal.name = close_signal_name
        signal.trading_operation_id = self.id
        signal.trading_position_id = position.id
        signal.close_quote_value = self.quote_target.get_quote_value_by_time_stamp["ask"]
        signal.trading_strategy_id = self.id
        signal.reason = "Closed by setting state to paused"
        Rails.logger.debug signal.inspect
        signal.save
      else
        Rails.logger.error("Can't find open signal name")
      end
    end
  end

  def population
    self.trading_strategy_population
  end

  def get_chart_data(current_day=nil)
    quote_values = []
    current_day = current_day ? current_day : Date.today
    from_date = current_day.to_datetime.beginning_of_day
    to_date = current_day.to_datetime.end_of_day
    quote_target.quote_values_by_range(from_date,to_date).each do |quote_value_source|
      quote_value = quote_value_source["_source"]
      datetime = DateTime.parse(quote_value["data_time"])
      quote_values<<"{date: new Date(#{datetime.year},#{datetime.month-1},#{datetime.day},#{datetime.hour},#{datetime.minute},0,0), value: #{quote_value["close"]}, close: #{quote_value["close"]}, open: #{quote_value["open"]}, high: #{quote_value["high"]}, low: #{quote_value["low"]}, volume: #{0}}"
    end
    quote_values.join(",")
  end

  def get_trading_events(current_day=nil)

    @from_hour = TradingTimeFrame.last.from_hour
    @to_hour = TradingTimeFrame.last.to_hour
    current_day = @day = current_day ? current_day : Date.today
    from_date = current_day.to_datetime.beginning_of_day
    to_date = current_day.to_datetime.end_of_day
    events = []
    events << simulated_trading_signal_to_amchart({:name=>"B", :current_date_time=>DateTime.parse("#{@day} #{@from_hour}:00:00"), :background_color=>"#22ee22",
                                                  :description=>"Trading Time Frame Start"})
    events << simulated_trading_signal_to_amchart({:name=>"E", :current_date_time=>DateTime.parse("#{@day} #{@to_hour}:00:00"), :background_color=>"#ff6655",
                                                  :description=>"Trading Time Frame Stop"})
    trading_signals.where(["created_at>=? AND created_at<=?",from_date.to_formatted_s(:db),to_date.to_formatted_s(:db)]).all.each do |signal|
      if signal.name=="Short Open" or signal.name=="Long Open"
        events << simulated_trading_signal_to_amchart({:name=>"O",
                                                       :type=>"sign",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=>"#cccccc",
                                                       :description=>"#{signal.open_quote_value} #{signal.reason}"})
        if signal.trading_strategy
          events << simulated_trading_signal_to_amchart({:name=>"O",
                                                         :type=>"flag",
                                                         :current_date_time=>signal.created_at.to_datetime-(signal.trading_strategy.open_how_far_back_milliseconds/1000/60).minutes,
                                                         :background_color=>"#aaccff",
                                                         :description=>signal.trading_strategy.id})
        end
      end
      if signal.name=="Short Close" or signal.name=="Long Close"
        events << simulated_trading_signal_to_amchart({:name=>signal.name, :type=>"arrowDown",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=>"#cccccc",
                                                       :description=>signal.close_quote_value})
        if signal.trading_strategy
          events << simulated_trading_signal_to_amchart({:name=>"C",
                                                       :type=>"flag",
                                                       :current_date_time=>signal.created_at.to_datetime-(signal.trading_strategy.close_how_far_back_milliseconds/1000/60).minutes,
                                                       :background_color=>"#ccccff",
                                                       :description=>signal.trading_strategy.id})
        end
        events << simulated_trading_signal_to_amchart({:name=>"#{signal.profit_loss.to_i}",
                                                       :type=>"sign",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=> signal.profit_loss>=0.0 ? "#44ff33" : "#ff3366",
                                                       :description=>"P/L #{signal.profit_loss} #{signal.reason}"})
      end
      if signal.name=="Stop Loss Open"
        events << simulated_trading_signal_to_amchart({:name=>"SL",
                                                       :type=>"arrowUp",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=>"#caccff",
                                                       :description=>"#{signal.open_quote_value} #{signal.reason}"})
      end
      if signal.name=="Stop Loss Close"
        events << simulated_trading_signal_to_amchart({:name=>"SL",
                                                       :type=>"arrowDown",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=>"#ffccac",
                                                       :description=>"#{signal.open_quote_value} #{signal.reason}"})
      end

    end
    events.join(",")
  end

  def simulated_trading_signal_to_amchart(event)
    background_color = event[:background_color] ? event[:background_color] : "#cccccc"
    event_type = event[:type] ? event[:type] : "sign"
    event_type = "arrowUp" if event[:name]=="Short Open"
    event_type = "arrowDown" if event[:name]=="Short Close"
    "{ date: new Date(#{event[:current_date_time].year},#{event[:current_date_time].month-1},#{event[:current_date_time].day},#{event[:current_date_time].hour},#{event[:current_date_time].minute},0,0), type: '#{event_type}', \
             backgroundColor: '#{background_color}', graph: graph1, text: '#{event[:name]}', description: '#{event[:description]}'}"
  end


end
