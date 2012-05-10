# encoding: UTF-8

class QuoteTarget < ActiveRecord::Base
  belongs_to :exchanges
  has_many :classified_paragraphs
  has_and_belongs_to_many :rss_items, :order => "rss_items.pubDate ASC" do
    def only_active
      find(:all).reject{|item| item.rss_target.active==false }      
    end
    
    def by_rand
      find(:all, :order=>"RAND()")
    end
    
    def get_not_rated
      find(:all, :order=>"RAND()", :limit=>100).reject{|item| item.classified_paragraphs.hasone?(self.id)!=nil or item.rss_target.active==false }[0]
    end
  end
  has_many :quote_values, :order => "created_at ASC" do
    def get_one_by_time(time_stamp)
      find :first, :conditions=>["created_at >= ?",time_stamp]
    end
  end
end
