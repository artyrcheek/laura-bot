require 'date'
require 'net/http'
require 'json'
require 'pp'
require 'slack-ruby-client'

require 'httparty'

date = DateTime.now
date -= 1
while date.wday == 0 || date.wday == 6
  date += inc
end
last_business_day = date.strftime("%Y-%m-%d")

start_date = last_business_day
end_date = last_business_day
datestring = 'last workday'

reports_response = HTTParty.post(
  "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
  body: {"report_type" => "timetracking", "start_date" => start_date, "end_date" => end_date}
)

userMap = {}

# Get all breeze users
usersResponse = HTTParty.get(
  "https://api.breeze.pm/users?api_token=B7ULqZ4WueSY-uv-yCZq",
)

reports_response.each do |report|
  pp report
  puts "-----------------"
  user_id = report['user_id']
  user_name = usersResponse.find do |user| user['id'] == user_id end['name']
  minutes_tracked = report['tracked']
  if user_name && user_id && minutes_tracked #somethings going wrong here
    if !userMap.has_key? user_name
      userMap[user_name] = minutes_tracked
    elsif
      userMap.has_key? user_name
      userMap[user_name] += minutes_tracked
    end
  end
end

return_attatchments = ""
userMap = userMap.sort_by{ |k, v| v }.reverse
position = 1
total_minutes_tracked = 0
userMap.each do |user, time_tracked|
  return_attatchments << "
    {
      'color': '#{ if time_tracked <= 300 then "danger" elsif time_tracked <= 390 then "warning" else "good" end}',
      'title': '#{user}',
      'text': '#{time_tracked/60} Hours #{time_tracked % 60} Minutes'
    },"
  total_minutes_tracked += time_tracked
  position += 1
end
