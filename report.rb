module Report
  def self.parse_slack_text(slack_text)
    if slack_text.include? "detailed" then detailed_mode = true else detailed_mode = false end

    #last_month,last_week, yesterday, today, this_week, this_month.
    if slack_text.include? "today"
      start_date = 'today'
      datestring = 'today'
    elsif slack_text.include? "yesterday"
      start_date = 'yesterday'
      datestring = 'yesterday'
    elsif slack_text.include? "this_week"
      start_date = 'this_week'
      datestring = 'this week'
    elsif slack_text.include? "this_month"
      start_date = 'this_month'
      datestring = 'this month'
    elsif slack_text.include? "help"
      error_response = "{'text': 'please include a timeframe after `/report`, you can use `today`, `yesterday`, or leave blank for the last workday'}"
      HTTParty.post(slack_data['response_url'], body: error_response)
      return
    else
      inc = -1
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

    slack_text_return_data = {
      "detailed_mode" => detailed_mode,
      "start_date" => start_date,
      "end_date" => end_date,
      "datestring" => datestring
    }

    return slack_text_return_data
  end
end

module ReportCallback
  def self.slack_reply(slack_data)
    # Parsing start date test in slack text
    slack_text = slack_data['text'].strip

    # if slack_text.include? "detailed"
    #   detailed_mode = true
    # else
    #   detailed_mode = false
    # end
    #
    # #last_month,last_week, yesterday, today, this_week, this_month.
    # if slack_text.include? "today"
    #   start_date = 'today'
    #   datestring = 'today'
    # elsif slack_text.include? "yesterday"
    #   start_date = 'yesterday'
    #   datestring = 'yesterday'
    # elsif slack_text.include? "this_week"
    #   start_date = 'this_week'
    #   datestring = 'this week'
    # elsif slack_text.include? "this_month"
    #   start_date = 'this_month'
    #   datestring = 'this month'
    # elsif slack_text.include? "help"
    #   error_response = "{'text': 'please include a timeframe after `/report`, you can use `today`, `yesterday`, or leave blank for the last workday'}"
    #   HTTParty.post(slack_data['response_url'], body: error_response)
    #   return
    # else
    #   inc = -1
    #   date = DateTime.now
    #   date -= 1
    #   while date.wday == 0 || date.wday == 6
    #     date += inc
    #   end
    #   last_business_day = date.strftime("%Y-%m-%d")
    #
    #   start_date = last_business_day
    #   end_date = last_business_day
    #   datestring = 'last workday'
    # end

    slack_text_return_object = Report.parse_slack_text(slack_text)

    start_date = slack_text_return_object["start_date"]
    end_date = slack_text_return_object["end_date"]
    detailed_mode = slack_text_return_object["detailed_mode"]
    datestring = slack_text_return_object["datestring"]

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
          if time_for_project >= 60
            timeString = "#{time_for_project/60} Hours #{time_for_project % 60} Minutes"
          else
            timeString = "#{time_for_project % 60} Minutes"
          end
          projectTimeFields << "{
            'title': '#{if project_name!= "" then project_name else "Project Name Empty" end}',
            'value': '#{timeString}',
            'short': false
          },"
        end
        return_attatchments << "
          {
            'color': '#{ if time_tracked <= 300 then "danger" elsif time_tracked <= 390 then "warning" else "good" end}',
            'title': '#{user}',
            'text': 'Total Time Tracked: *#{time_tracked/60} Hours #{time_tracked % 60} Minutes*',
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

    time_tracking_report_body = "
      {
        'response_type':'in_channel',
        'text': '*#{if detailed_mode then "Detailed " end}Time Tracking Report For #{datestring.titleize }* from <@#{slack_data['user_id']}> \n Total time tracked: *#{total_minutes_tracked/60} Hours #{total_minutes_tracked % 60} Minutes*',
        'attachments': [#{ return_attatchments[0..-1] }]
      }"
    HTTParty.post(slack_data['response_url'], body: time_tracking_report_body)
  end
end
