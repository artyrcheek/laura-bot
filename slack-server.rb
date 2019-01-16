require 'net/http'
require 'json'
require 'slack-ruby-client'
require 'sinatra'
require 'httparty'

def get_json_url_with_params(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(uri)
  response_body = res.body.to_s
  return JSON.parse(response_body)
end
# cards =  get_json_url_with_params('https://api.breeze.pm/v2/cards/', { :api_token => 'B7ULqZ4WueSY-uv-yCZq', :assigned_id => '41569' })


def slack_callback(slack_data)
  puts "callback triggered! :)"
  return_attatchments = ""
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
          # return_attatchments << "#{entry['user_name']} - #{card['name']} app.breeze.pm/cards/#{card['id']} \n"
          return_attatchments << "{
            'color': '#36a64f',
            'author_name': '#{entry['user_name']}',
            'author_link': 'https://app.breeze.pm/tasks/board?utf8=%E2%9C%93&users%5B%5D=#{entry['user_id']}',
            'title': '#{card['name']}',
            'title_link': 'app.breeze.pm/cards/#{card['id']}',
            'text': '#{card['project']['name']}'
        },"
        end
      end
    end
    num_cards = cards.length
    i+= 1
  end
  return_attatchments ||= "No one is tracking time!"
  HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text':'#{return_message}'}  { 'attachments': [#{ return_attatchments[0..-1] }] }")
end

post "/whostracking" do
  content_type :json
  status 200
  slack_data = request.POST
  Thread.new do
    slack_callback(slack_data)
  end
  return "one minute, scanning breeze"
end

get '/' do
  return "I AM LAURABOT!!!!"
end
