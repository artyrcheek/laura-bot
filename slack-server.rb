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
# Finally fully working!

def slack_whos_tracking_callback(slack_data)
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
            'title_link': 'https://app.breeze.pm/cards/#{card['id']}/',
            'text': '#{card['project']['name']}'
        },"
        end
      end
    end
    num_cards = cards.length
    i+= 1
  end
  if return_attatchments == ""
    return_attatchments = "{ 'color': 'warning', 'title': 'No one is tracking time!' },"
  end
  HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text': '*Current Tracking Report* from <@#{slack_data['user_id']}>', 'attachments': [#{ return_attatchments[0..-1] }] }")
end

def slack_report_callback(slack_data)
  # Get all breeze users
  usersResponse = HTTParty.get(
    "https://api.breeze.pm/users?api_token=B7ULqZ4WueSY-uv-yCZq",
  )
  # Parsing start date test in slack text
  start_date = slack_data['text'].strip
  #last_month,last_week, yesterday, today, this_week, this_month .
  case start_date
    when 'today'
      start_date = 'today'
    when 'yesterday'
      start_date = 'yesterday'
    when 'last_week'
      start_date = 'last_week', 'last week'
    when 'last_month'
      start_date = 'last_month', 'last week'
    when 'this_week'
      start_date = 'this_week', 'this week'
    when 'this_month'
      start_date = 'this_month', 'this month'
    else
      error_response = "{'text': 'please include a timeframe after /report, you can use last_month,last_week, yesterday, today, this_week, this_month'}"
      HTTParty.post(slack_data['response_url'], body: error_response)
      return
  end




  reports_response = HTTParty.post(
    "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
    body: {"report_type" => "timetracking", "start_date" => start_date }
  )

  userMap = {}

  reports_response.each do |report|
    user_id = report['user_id']
    user_name = usersResponse.find do |user| user['id'] == user_id end['name']
    minutes_tracked = report['tracked']
    if user_name && user_id && minutes_tracked
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

  time_tracking_report_body = "
    {
      'response_type':'in_channel',
      'text': '*Time Tracking Report For #{start_date.titleize }* from <@#{slack_data['user_id']}> \n Total time tracked: *#{total_minutes_tracked/60} Hours #{total_minutes_tracked % 60} Minutes*',
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
      error_response = "
        {
          'text': 'Sorry, something went wrong before trying to read breeze'
        }"
      HTTParty.post(slack_data['response_url'], body: error_response)
    end
  end
  return "one minute, scanning breeze"
end

post "/report" do
  content_type :json
  status 200
  slack_data = request.POST
  Thread.new do
    begin
      slack_report_callback(slack_data)
    rescue
      error_response = "
        {
          'text': 'Sorry, something went wrong before trying to scan breeze reports'
        }"
      HTTParty.post(slack_data['response_url'], body: error_response)
    end
  end
  return "Getting Report data"
end
