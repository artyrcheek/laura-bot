require 'net/http'
require 'json'
require 'slack-ruby-client'

require 'sinatra'

post '/whostracking' do
  content_type :json
  status 200
  # return return_currently_tracked_entries()
  # push = JSON.parse(request.body.read)
  # puts "I got some JSON: #{push.inspect}"
  return '{ "response_type": "in_channel", "text": "Its 80 degrees right now.", "attachments": [ { "text":"Partly cloudy today and tomorrow" } }'
end

get '/whostracking' do
  content_type :json
  response = { "text" => "hello there!"}
  status 200
  response.to_json

end

get '/' do
  return "yeet"
end
