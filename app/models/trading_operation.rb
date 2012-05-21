class TradingOperation < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :quote_target
  belongs_to :trading_account
  belongs_to :trading_strategy_population
  has_many :trading_positions
  has_many :trading_signals

  def get_chart_data(day_offset=0)
    day_offset = 0 unless day_offset
    quote_values = []
    @day = self.created_at.to_date+day_offset #(self.simulated_start_date+4).to_date
    (00..23).each do |hour|
      (0..59).each do |minute|
        current_quote_value = self.quote_target.get_quote_value_by_time_stamp(DateTime.parse("#{@day} #{hour}:#{minute}:00"))
        quote_values<<"{date: new Date(#{@day.year},#{@day.month},#{@day.day},#{hour},#{minute},0,0), value: #{current_quote_value.ask}, volume: #{0}}" if current_quote_value
      end
    end
    quote_values.join(",")
  end

  def get_trading_events(day_offset=0)
    day_offset = 0 unless day_offset
    @from_hour = TradingTimeFrame.last.from_hour
    @to_hour = TradingTimeFrame.last.to_hour
    @day = self.created_at.to_date+day_offset
    events = []
    events << simulated_trading_signal_to_amchart({:name=>"B", :current_date_time=>DateTime.parse("#{@day} #{@from_hour}:00:00"), :background_color=>"#22ee22",
                                                  :description=>"Trading Time Frame Start"})
    events << simulated_trading_signal_to_amchart({:name=>"E", :current_date_time=>DateTime.parse("#{@day} #{@to_hour}:00:00"), :background_color=>"#ff6655",
                                                  :description=>"Trading Time Frame Stop"})
    trading_signals.each do |signal|
      if signal.name=="Short Open"
        events << simulated_trading_signal_to_amchart({:name=>"F", :type=>"flag",
                                                       :current_date_time=>signal.created_at.to_datetime-(signal.trading_strategy.how_far_back_milliseconds/1000/60).minutes,
                                                       :background_color=>"#aaccff",
                                                       :description=>signal.trading_strategy.id})
        events << simulated_trading_signal_to_amchart({:name=>signal.name, :type=>"arrowUp",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=>"#cccccc",
                                                       :description=>signal.open_quote_value})
      end
      if signal.name=="Short Close"
        events << simulated_trading_signal_to_amchart({:name=>signal.name, :type=>"arrowDown",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=>"#cccccc",
                                                       :description=>signal.close_quote_value})

        events << simulated_trading_signal_to_amchart({:name=>"#{signal.profit_loss.to_i}",
                                                       :type=>"sign",
                                                       :current_date_time=>signal.created_at.to_datetime,
                                                       :background_color=> signal.profit_loss>=0.0 ? "#44ff33" : "#ff3366",
                                                       :description=>"P/L #{signal.profit_loss}"})
      end
    end
    events.join(",")
  end

  def simulated_trading_signal_to_amchart(event)
    background_color = event[:background_color] ? event[:background_color] : "#cccccc"
    event_type = event[:type] ? event[:type] : "sign"
    event_type = "arrowUp" if event[:name]=="Short Open"
    event_type = "arrowDown" if event[:name]=="Short Close"
    "{ date: new Date(#{event[:current_date_time].year},#{event[:current_date_time].month},#{event[:current_date_time].day},#{event[:current_date_time].hour},#{event[:current_date_time].minute},0,0), type: '#{event_type}', \
             backgroundColor: '#{background_color}', graph: graph1, text: '#{event[:name]}', description: '#{event[:description]}'}"
  end


end
