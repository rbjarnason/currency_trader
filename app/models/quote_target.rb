# encoding: UTF-8

class QuoteTarget < ActiveRecord::Base
  @@quote_value_cache = {}
  @@quote_value_cache_timer = Time.now+10.minutes

  ::MEMORY_STORE = ActiveSupport::Cache::MemoryStore.new(:size=>256.megabytes)

  def quote_values_by_range(from,to,size=10000)
    client = Elasticsearch::Client.new host: ES_HOST, log: true
    results = client.search(
        :index => "quotes-*",
        :search_type => "query_then_fetch",
        :size => size,
        :type  => "quote",
        :body  => {
            query: {
                :filtered => {
                    :filter => {
                        :range => {
                            :data_time => { gte: from, lte: to }
                        }
                    }
                }
            }
        })
    return results["hits"]["hits"]
  end

  def get_quote_value_by_time_stamp(time_stamp=nil)
    time_stamp_key = time_stamp ? "#{time_stamp.strftime("%Y_%m_%d_%H:%M")}_#{self.id}" : nil
    results = MEMORY_STORE.read(time_stamp_key) if time_stamp_key
    if time_stamp_key and results
      return_this = results unless results == "no_quote"
      if results != "no_quote"
        return_this
      else
        nil
      end
    else
      if time_stamp
        if quote_value = quote_values_by_range(time_stamp,time_stamp+1.minutes,1).first["_source"]
          MEMORY_STORE.write(time_stamp_key,quote_value) if quote_value
          quote_value
        end
      else
        quote_values_by_range(DateTime.now-5.years,DateTime.now-1.minutes,1).first["_source"]
      end
    end
  end

end
