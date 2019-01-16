require 'net/http'
require 'json'
require 'slack-ruby-client'

require 'sinatra'

get '/whostracking' do
  content_type :json
  # return return_currently_tracked_entries()
  return "hello"
end

post '/whostracking' do
  content_type :json
  response = '{ "text": "It's 80 degrees right now.", "attachments": [ { "text":"Partly cloudy today and tomorrow" } ] }'
  status 200
  JSON.parse(response)
end

get '/' do
  return "yeet"
end
