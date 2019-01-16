require 'net/http'
require 'json'
require 'slack-ruby-client'

require 'sinatra'
# require_relative './laura-bot.rb'

def get_json_url_with_params(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(uri)
  response_body = res.body.to_s
  return JSON.parse(response_body)
end

def return_currently_tracked_entries
  i = 1
  num_cards = 1
  tracked_entries = []
  puts "here"
  while num_cards > 0
    puts "checking page #{i}"
    cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :page => i})
    cards.each do |card|
      # puts "card with id: #{card['id']} and name: #{card['name']}"
      # puts "#{card['name']} in project: #{card['project']['name']}"
      card["time_entries"].each do  |entry|
        if entry["tracked"] == nil
          tracked_entries << "#{entry['user_name']} - #{card['name']}"
        end
      end
    end
    num_cards = cards.length
    i+= 1
  end
  puts "Done"
  return tracked_entries.to_json
end

get '/whostracking' do
  content_type :json
  return return_currently_tracked_entries()
end
