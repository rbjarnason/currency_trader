# encoding: UTF-8

class QuoteTarget < ActiveRecord::Base
  @@quote_value_cache = {}
  @@quote_value_cache_timer = Time.now+10.minutes

  has_many :quote_values, :order => "created_at ASC" do
    def get_one_by_time(time_stamp)
      find :first, :conditions=>["created_at >= ?",time_stamp]
    end
  end

  def get_quote_value_by_time_stamp_2(time_stamp=nil)
    time_stamp_key = time_stamp ? time_stamp.strftime("%Y_%m_%d_%H:%M") : nil
    if time_stamp_key and @@quote_value_cache[time_stamp_key]
      return_this = @@quote_value_cache[time_stamp_key] unless @@quote_value_cache[time_stamp_key] == "no_quote"
      if @@quote_value_cache_timer<Time.now
        Rails.logger.debug("CLEARING QUOTE VALUE CACHE")
        @@quote_value_cache.clear
        @@quote_value_cache_timer = Time.now+100000000.minutes
      end
      if @@quote_value_cache[time_stamp_key] != "no_quote"
        return_this
      else
        nil
      end
    else
      if time_stamp
        if quote_value = quote_values.where(["created_at >= ?",time_stamp]).first
          @@quote_value_cache[time_stamp_key] = quote_value
        else
          @@quote_value_cache[time_stamp_key] = "no_quote"
          nil
        end
      else
        quote_values.last
      end
    end
  end

  def get_quote_value_by_time_stamp(time_stamp=nil)
    time_stamp_key = time_stamp ? "#{time_stamp.strftime("%Y_%m_%d_%H:%M")}_#{self.id}" : nil
    results = Rails.cache.read(time_stamp_key) if time_stamp_key
    if time_stamp_key and results
      return_this = results unless results == "no_quote"
      if results != "no_quote"
        return_this
      else
        nil
      end
    else
      if time_stamp
        if quote_value = quote_values.where(["created_at >= ?",time_stamp]).first
          Rails.cache.write(time_stamp_key,quote_value)
          quote_value
        end
      else
        quote_values.last
      end
    end
  end

end
