require 'net/http'
require 'json'
require 'slack-ruby-client'
require 'httparty'
load './gradient.rb'
#
# puts "callback triggered! :)"
# return_attatchments = ""
# i = 1
# people_tracking = 0
# num_cards = 1
# while num_cards > 0
#   puts "checking page #{i}"
#   # cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :page => i})
#   cards = HTTParty.get(
#     "https://api.breeze.pm/v2/cards/",
#     body: {"api_token" => "B7ULqZ4WueSY-uv-yCZq", "page" => i }
#   )
#   cards.select! do |card|
#     card['stage']['name'].exclude? 'Done'
#   end
#   cards.each do |card|
#     puts card['stage']['name']
#   end
#   cards.each do |card|
#     # puts "card with id: #{card['id']} and name: #{card['name']}"
#     # puts "#{card['name']} in project: #{card['project']['name']}"
#     card["time_entries"].each do  |entry|
#       if entry["tracked"] == nil
#         # return_attatchments << "#{entry['user_name']} - #{card['name']} app.breeze.pm/cards/#{card['id']} \n"
#         return_attatchments << "{
#           'color': 'good',
#           'author_name': '#{entry['user_name']}',
#           'author_link': 'https://app.breeze.pm/tasks/board?utf8=%E2%9C%93&users%5B%5D=#{entry['user_id']}',
#           'title': '#{card['name']}',
#           'title_link': 'https://app.breeze.pm/cards/#{card['id']}/',
#           'text': '#{card['project']['name']}'
#         },"
#         people_tracking += 1
#       end
#     end
#   end
#   num_cards = cards.length
#   i+= 1
# end
# puts "got here #{people_tracking} tracking"
#
# end
puts "callback triggered! :)"
return_attatchments = ""
page_number = 1
people_tracking = 0
num_cards = 1
while num_cards > 0
  puts "checking page #{page_number}"
  # cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :page => i})
  cards = HTTParty.get(
    "https://api.breeze.pm/v2/cards/",
    body: {"api_token" => "B7ULqZ4WueSY-uv-yCZq", "page" => page_number }
  )
  cards.select! do |card|
    card['stage']['name'].exclude? 'Done'
  end
  cards.each do |card|
    # puts "card with id: #{card['id']} and name: #{card['name']}"
    # puts "#{card['name']} in project: #{card['project']['name']}"
    card["time_entries"].each do  |entry|
      if entry["tracked"] == nil
        # return_attatchments << "#{entry['user_name']} - #{card['name']} app.breeze.pm/cards/#{card['id']} \n"
        return_attatchments << "{
          'color': 'good',
          'author_name': '#{entry['user_name']}',
          'author_link': 'https://app.breeze.pm/tasks/board?utf8=%E2%9C%93&users%5B%5D=#{entry['user_id']}',
          'title': '#{card['name']}',
          'title_link': 'https://app.breeze.pm/cards/#{card['id']}/',
          'text': '#{card['project']['name']}'
        },"
        people_tracking += 1
      end
    end
  end
  num_cards = cards.length
  # HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text': 'finished scanning page #{i} with #{people_tracking} people tracking' }")
  page_number += 1
end
# HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text': 'finished scanning with #{people_tracking} people tracking' }")
if return_attatchments == ""
  return_attatchments = "
    {
      'color': 'warning',
      'title': 'No one is tracking time!',
    },"
  end
# HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'attachments': [#{ return_attatchments[0..-1] }] }")
