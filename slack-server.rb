require 'net/http'
require 'json'
require 'slack-ruby-client'

require 'sinatra'

post '/whostracking' do
  content_type :json
  # return return_currently_tracked_entries()
  puts request.POST.inspect
  return "hello"
end

get '/' do
  return "yeet"
end
