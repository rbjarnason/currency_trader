class TradingOperation < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :quote_target
  belongs_to :trading_account
  belongs_to :trading_strategy_population
  has_many :trading_positions
  has_many :trading_signals


  def population
    self.trading_strategy_population
  end

  def get_chart_data(current_day=nil)
    quote_values = []
    current_day = current_day ? current_day : Date.today
    from_date = current_day.to_datetime.beginning_of_day
    to_date = current_day.to_datetime.end_of_day
    quote_target.quote_values.where(["data_time>=? AND data_time<=?",from_date.to_formatted_s(:db),to_date.to_formatted_s(:db)]).all.each do |quote_value|
      quote_values<<"{date: new Date(#{quote_value.data_time.year},#{quote_value.data_time.month-1},#{quote_value.data_time.day},#{quote_value.data_time.hour},#{quote_value.data_time.min},0,0), value: #{quote_value.ask}, volume: #{0}}"
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
