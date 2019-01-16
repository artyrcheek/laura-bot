require 'net/http'
require 'json'
require 'slack-ruby-client'


# deaths = []
#
# dronejson = open('https://api.breeze.pm/projects/109831/cards/').read
# dronejson = JSON.parse dronejson
# puts dronejson

def get_json_url_with_params(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(uri)
  response_body = res.body.to_s
  return JSON.parse(response_body)
end

def print_currently_tracked_cards(cards)
  cards.each do |card|
    # puts "card with id: #{card['id']} and name: #{card['name']}"
    # puts "#{card['name']} in project: #{card['project']['name']}"
    card["time_entries"].each do  |entry|
      if entry["tracked"] == nil
        puts "#{entry['user_name']} - #{card['name']}"
      end
    end
  end
end

# cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :assigned_id => '41569' })
i = 1
num_cards = 1
while num_cards > 0
  # puts "checking page #{i}"
  cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :page => i})
  print_currently_tracked_cards(cards)
  num_cards = cards.length
  i+= 1
end
puts "Done"
