require 'rubygems'
require 'open-uri'

doc = Hpricot(open("http://www.technorati.com/blogs/directory/business/investing?page=1"))
(doc/"/html/body/div[3]/div[4]/div/div[2]/ol/li/div[2]/a").each do |e|
  e.each do |e2|
    puts e2.to_s
  end
end

