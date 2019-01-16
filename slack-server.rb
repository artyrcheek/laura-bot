require 'net/http'
require 'json'
require 'slack-ruby-client'
require 'sinatra'

def get_json_url_with_params(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(uri)
  response_body = res.body.to_s
  return JSON.parse(response_body)
end
# cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :assigned_id => '41569' })


def slack_callback(slack_data)
  return_message = ""
  i = 1
  num_cards = 1
  while num_cards > 0
    puts "checking page #{i}"
    cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :page => i})
    cards.each do |card|
      # puts "card with id: #{card['id']} and name: #{card['name']}"
      # puts "#{card['name']} in project: #{card['project']['name']}"
      card["time_entries"].each do  |entry|
        if entry["tracked"] == nil
          return_message << "#{entry['user_name']} - #{card['name']} \n"
        end
      end
    end
    num_cards = cards.length
    i+= 1
  end
  puts return_message
end



post "/whostracking" do
  content_type :json
  slack_data = request.POST.inspect
  slack_callback(slack_data)
  return "one minute, gathering data"
end

get '/' do
  return "yeet"
end
