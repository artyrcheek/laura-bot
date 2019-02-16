require 'date'
require 'net/http'
require 'json'
require 'pp'
require 'slack-ruby-client'

require 'httparty'

todaysDate = true
page = 0
correctDateActivites = []
while todaysDate
  #Get Activities
  activities = HTTParty.get("https://api.breeze.pm/activities.json?api_token=B7ULqZ4WueSY-uv-yCZq&page=#{page}",)
  #Select Activities that have the correct created at date
  activities.select! do |activity|
    activity["created_at"].include? "2019-02-15"
  end
  #if activities arent empty select the ones which are moved list and add them to an array
  if activities.count != 0
    activities.select! do |activity|
      activity["action"] == "moved list"
    end
    activities.each do |activity|
      correctDateActivites << activity
    end
  else
    break
  end
  page += 1
end

correctDateActivites.each do |activity|
  puts activity["action"]
  puts "#{activity["user"]["name"]} moved #{activity["card"]["name"]} from #{activity["item_old"]} to #{activity["item"]["changed"]}"
end
