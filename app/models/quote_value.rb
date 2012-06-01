# encoding: UTF-8

class QuoteValue < ActiveRecord::Base
  belongs_to :quote_target

  def normalize_float(number,position=nil)
    if number
      number = number.abs #normalize to 0..1
      if number>0.0 and number>1.0
        begin
          number/=10.0
        end while number>1.0
      end
      if position and @inputs_scaling
        scale_number=@inputs_scaling[position].abs
        if scale_number>1000
          scale=1000.0
        elsif scale_number>100
          scale=100.0
        elsif scale_number>10
          scale=10.0
        else
          scale=1.0
        end
      else
        scale=1.0
      end
      number/[scale,1.0].max
    else
      0.0
    end
  end

  def normalize_up_or_down(number)
    number>0.0 ? 1.0 : 0.0
  end

  def get_neural_input(selected_inputs,inputs_scaling)
    @inputs_scaling = inputs_scaling
    features = []
    features << normalize_float(self.ask,0) if selected_inputs[0]==1
    # 55 RESERVED FOR CASCADE OR NORMAL TRAINING MODE
    # 56 RESERVED FOR sell_by_prediction 
    features
  end

  def get_desired_output
    normalize_float(self.last_trade.to_f)
  end

  def import_yahoo_csv_data(quote_data)
    self.ask = quote_data[0].to_f
  end

  def import_csv_data(quote_data)
    Rails.logger.debug(quote_data.inspect)
    self.timestamp_ms = quote_data[1].to_i
    self.bid_big_figure = quote_data[2].to_f
    self.bid_points = quote_data[3].to_f
    self.bid = "#{self.bid_big_figure}#{self.bid_points.to_i}"
    self.offer_big_figure = quote_data[4].gsub("#","").to_f
    self.offer_points = quote_data[5].to_f
    self.offer = "#{self.offer_big_figure}#{self.offer_points.to_i}"
    self.high = quote_data[6].to_f
    self.low = quote_data[7].to_f
    self.open = quote_data[8].to_f
    self.ask = self.bid
  end

private
  def parse_value(in_value)
    out_value = nil
    out_value = in_value.to_f if in_value and in_value!="N/A" and in_value!="N/A\r\n" and in_value!="-"
    out_value
  end

  def parse_b_value(in_value)
    out_value = nil
    if in_value
      in_value2 = in_value.gsub(".","")
      in_value3 = nil
      if in_value2[in_value2.length-1...in_value2.length]=="B"
        in_value3 = in_value2[0...in_value2.length-1].to_f * 1000
      elsif in_value2[in_value2.length-1...in_value2.length]=="M"
        in_value3 = in_value2[0...in_value2.length-1].to_f
      else
        in_value3 = in_value2.to_f
      end
      out_value = in_value3
    end
    out_value
  end
end
