require 'net/http'
require 'json'
require 'slack-ruby-client'
# require 'sinatra'
require 'httparty'

usersResponse = HTTParty.get(
  "https://api.breeze.pm/users?api_token=B7ULqZ4WueSY-uv-yCZq",
)
reports_response = HTTParty.post(
  "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
  body: {"report_type" => "timetracking", "start_date" => "yesterday" }
)

# reports_response.each do |s|
#   puts s['user_id']
#   user_name = usersResponse.each do |user|
#     puts user
#     puts user['id']
#     # user['id'] == id
#   end['name']
#   puts
# end
userMap = {}

reports_response.each do |report|
  user_id = report['user_id']
  user_name = usersResponse.find do |user| user['id'] == user_id end['name']
  minutes_tracked = report['tracked']
  if !userMap.has_key? user_name
    userMap[user_name] = minutes_tracked
  elsif
    userMap.has_key? user_name
    userMap[user_name] += minutes_tracked
  end
end
