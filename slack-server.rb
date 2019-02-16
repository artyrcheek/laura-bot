require 'net/http'
require 'json'
require 'slack-ruby-client'
require 'sinatra'
require 'httparty'

# Harvest
#PERSONAL_ACCESS_TOKEN = ENV["568833.pt.WqVZaB62RnKFoiPrGWZ_63OcI8YT_SZ5ylgCfjLCuaAYRAGy-3IPNgaFEdQjeqpxTC2MOEGFKTgYx-LUG_fDVw"]
#ACCOUNT_ID = ENV["486922"]

def get_json_url_with_params(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(uri)
  response_body = res.body.to_s
  return JSON.parse(response_body)
end

def slack_whos_tracking_callback(slack_data)
  return_attatchments = ""
  reports_response = HTTParty.post(
    "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
    body: {"report_type" => "timetracking", "start_date" => "today" }
  )
  reports_response.each do | entry |
    if entry['tracked'] == nil
      card = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}/cards/#{entry["card_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
      project = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
      better_entry = card['time_entries'].select do |newentry| newentry['id'] == entry['id'] end[0]
      return_attatchments << "{
        'color': '#36a64f',
        'author_name': '#{better_entry['user_name']}',
        'author_link': 'https://app.breeze.pm/tasks/board?utf8=%E2%9C%93&users%5B%5D=#{better_entry['user_id']}',
        'title': '#{card['name']}',
        'title_link': 'https://app.breeze.pm/cards/#{card['id']}/',
        'text': '#{project['name']}'
      },"
    end
  end

  if return_attatchments == ""
    return_attatchments = "{ 'color': 'warning', 'title': 'No one is tracking time!' },"
  end
  HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text': '*Current Tracking Report* from <@#{slack_data['user_id']}>', 'attachments': [#{ return_attatchments[0..-1] }] }")
end

def slack_report_callback(slack_data)
  # Parsing start date test in slack text
  slack_text = slack_data['text'].strip

  if slack_text.include? "detailed"
    detailed_mode = true
  else
    detailed_mode = false
  end

  #last_month,last_week, yesterday, today, this_week, this_month.
  if slack_text.include? "today"
    start_date = 'today'
    datestring = 'today'
  elsif slack_text.include? "yesterday"
    start_date = 'yesterday'
    datestring = 'yesterday'
  elsif slack_text.include? "help"
    error_response = "{'text': 'please include a timeframe after `/report`, you can use `today`, `yesterday`, or leave blank for the last workday'}"
    HTTParty.post(slack_data['response_url'], body: error_response)
    return
  else
    date = DateTime.now
    date -= 1
    while date.wday == 0 || date.wday == 6
      date += inc
    end
    last_business_day = date.strftime("%Y-%m-%d")

    start_date = last_business_day
    end_date = last_business_day
    datestring = 'last workday'
  end

  reports_response = HTTParty.post(
    "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
    body: {"report_type" => "timetracking", "start_date" => start_date, "end_date" => end_date}
  )

  userMap = {}
  if detailed_mode
    userProjectMap = {}
  end

  # Get all breeze users
  usersResponse = HTTParty.get(
    "https://api.breeze.pm/users?api_token=B7ULqZ4WueSY-uv-yCZq",
  )

  reports_response.each do |report|
    user_id = report['user_id']
    user_name = usersResponse.find do |user| user['id'] == user_id end['name']
    minutes_tracked = report['tracked']
    if user_name && user_id && minutes_tracked #somethings going wrong here
      if detailed_mode
        # add project => Time Map to userProjectMap[user_name] and add time to userMap[user_name]
        project = HTTParty.get("https://api.breeze.pm/projects/#{report["project_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
        project_name = project["name"]

        #Make empty hash for user if doesnt exist
        if userProjectMap[user_name] == nil
          userProjectMap[user_name] = {}
        end
        #Populate hash if does exist
        if userProjectMap[user_name][project_name] == nil
          userProjectMap[user_name][project_name] = minutes_tracked
        elsif userProjectMap[user_name][project_name] != nil
          userProjectMap[user_name][project_name] += minutes_tracked
        end
        # add time to userMap[user_name]
        if userMap[user_name] == nil
          userMap[user_name] = minutes_tracked
        elsif userMap[user_name] != nil
          userMap[user_name] += minutes_tracked
        end
      else
        # just add time to userMap[user_name]
        if userMap[user_name] == nil
          userMap[user_name] = minutes_tracked
        elsif userMap[user_name] != nil
          userMap[user_name] += minutes_tracked
        end
      end
    end
  end

  return_attatchments = ""
  userMap = userMap.sort_by{ |k, v| v }.reverse
  position = 1
  total_minutes_tracked = 0
  userMap.each do |user, time_tracked|
    if detailed_mode
      projectTimeFields = ""
      userProjectMap[user].each do |project_name, time_for_project|
        projectTimeFields << "{
          'title': '#{project_name}',
          'value': '*#{time_for_project/60} Hours #{time_for_project % 60} Minutes',
          'short': false
        },"
      end
      return_attatchments << "
        {
          'color': '#{ if time_tracked <= 300 then "danger" elsif time_tracked <= 390 then "warning" else "good" end}',
          'author_name': '#{user}',
          'title': 'Total Time Tracked: #{time_tracked/60} Hours #{time_tracked % 60} Minutes',
          'fields': [#{projectTimeFields[0..-1]}]
        },"
    else
      return_attatchments << "
        {
          'color': '#{ if time_tracked <= 300 then "danger" elsif time_tracked <= 390 then "warning" else "good" end}',
          'title': '#{user}',
          'text': '#{time_tracked/60} Hours #{time_tracked % 60} Minutes'
        },"
    end
    total_minutes_tracked += time_tracked
    position += 1
  end

  # Harvest
  #puts "Harvest Test"

  #uri = URI("https://api.harvestapp.com/v2/users/me")

  #Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
  #  request = Net::HTTP::Get.new uri
  #  request["User-Agent"] = "Ruby Harvest API"
  #  request["Authorization"] = "Bearer #{PERSONAL_ACCESS_TOKEN}"
  #  request["Harvest-Account-ID"] = ACCOUNT_ID

  #  response = http.request request
  #  json_response = JSON.parse(response.body)

  #  puts JSON.pretty_generate(json_response)
  #end

  # End Harvest

  time_tracking_report_body = "
    {
      'response_type':'in_channel',
      'text': '*#{if detailed_mode then "Detailed " end}Time Tracking Report For #{datestring.titleize }* from <@#{slack_data['user_id']}> \n Total time tracked: *#{total_minutes_tracked/60} Hours #{total_minutes_tracked % 60} Minutes*',
      'attachments': [#{ return_attatchments[0..-1] }]
    }"
  HTTParty.post(slack_data['response_url'], body: time_tracking_report_body)
end

post "/whostracking" do
  content_type :json
  status 200
  slack_data = request.POST
  Thread.new do
    begin
      slack_whos_tracking_callback(slack_data)
    rescue
      error_response = "{'text': 'Sorry, something went wrong before trying to read breeze'}"
      HTTParty.post(slack_data['response_url'], body: error_response)
    end
  end
  return "one minute, scanning breeze"
end

post "/report" do
  puts "/report requested"
  content_type :json
  status 200
  slack_data = request.POST
  Thread.new do
    begin
      slack_report_callback(slack_data)
    rescue
      error_response = "{'text': 'Sorry, something went wrong before trying to scan breeze reports'}"
      HTTParty.post(slack_data['response_url'], body: error_response)
    end
  end
  return "Getting Report data"
end
