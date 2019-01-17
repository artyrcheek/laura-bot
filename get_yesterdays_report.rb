require 'net/http'
require 'json'
require 'httparty'

def get_users()
  response = HTTParty.get(
    "https://api.breeze.pm/users?api_token=B7ULqZ4WueSY-uv-yCZq",
  )
  response
end

def get_yesterdays_reports()
  reports_body = {"report_type" => "timetracking", "start_date" => "yesterday" }
  response = HTTParty.post(
    "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
    body: reports_body
  )
  response
end

$all_users=get_users()
def get_user_by_id(id)
  $all_users.find do |user|
    user['id'] == id
  end
end

userMap = {}

get_yesterdays_reports().each do |report|
  user_id = report['user_id']
  user_name = get_user_by_id(user_id)['name']
  minutes_tracked = report['tracked']
  if !userMap.has_key? user_name
    userMap[user_name] = minutes_tracked
  elsif
    userMap.has_key? user_name
    userMap[user_name] += minutes_tracked
  end
end

userMap.each do |user_name, minutes_tracked|
  puts "#{user_name} did #{minutes_tracked}"
end


# puts get_user_by_id(28931)['name']
