require 'date'
require 'net/http'
require 'json'
require 'pp'
require 'slack-ruby-client'
require 'httparty'


API_TOKEN = "B7ULqZ4WueSY-uv-yCZq"

module ProjectReport

  def self.parse_slack_text(slack_text)
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
    elsif slack_text.include? "last_week"
      start_date = 'last_week'
      datestring = 'last week'
    elsif slack_text.include? "last_month"
      start_date = 'last_month'
      datestring = 'last month'
    else
      start_date = 'last_week'
      datestring = 'last week'
    end

    slack_text_return_data = {
      "start_date" => start_date,
      "datestring" => datestring
    }

    return slack_text_return_data
  end


  def self.get_reports_response_and_datestring(slack_text)
    slack_text_data = self.parse_slack_text(slack_text)

    slack_text_return_object = Report.parse_slack_text(slack_text)
    start_date, datestring = slack_text_return_object["start_date"], slack_text_return_object["datestring"]

    reports_response = HTTParty.post(
      "https://api.breeze.pm/reports?api_token=#{API_TOKEN}",
      body: {"report_type" => "timetracking", "start_date" => start_date}
    )
    return reports_response, datestring
  end

  def self.parse_reports_to_id_time_hash (reports_response)
    #Making a hash with the project id and the time tracked
    project_id_time_map = {}
    reports_response.each do |report|
      time_tracked = report["tracked"]
      project_id = report["project_id"]
      if project_id_time_map[project_id] == nil
        project_id_time_map[project_id] = time_tracked
      else
        project_id_time_map[project_id] += time_tracked
      end
    end
    project_id_time_map
  end

  def self.parse_id_time_hash_to_name_time_hash (project_id_time_map)
    #Making a hash with the project name and the time tracked
    project_name_time_tracked_hash = {}
    project_id_time_map.each do |project_id, time_tracked|
      project = HTTParty.get("https://api.breeze.pm/projects/#{project_id}.json?api_token=#{API_TOKEN}",)
      project_name = project["name"]
      project_name_time_tracked_hash[project_name] = time_tracked
    end
    project_name_time_tracked_hash
  end

  def self.get_name_time_hash_and_datestring(slack_data)
    reports_response, datestring = self.get_reports_response_and_datestring(slack_data["text"].strip)
    id_time_hash = self.parse_reports_to_id_time_hash(reports_response)
    name_time_hash = self.parse_id_time_hash_to_name_time_hash(id_time_hash)
    return name_time_hash, datestring
  end

end

module ProjectReportCallback
  def self.slack_reply (slack_data)
    # Parsing start date test in slack text
    slack_text = slack_data['text'].strip

    project_name_time_hash, datestring = ProjectReport.get_name_time_hash_and_datestring(slack_data)

    return_attatchments = ""
    project_name_time_hash = project_name_time_hash.sort_by{ |k, v| v }.reverse
    total_minutes_tracked = 0

    project_name_time_hash.each do |project_name, time_tracked|
      return_attatchments << "
        {
          'title': '#{project_name}',
          'text': '#{time_tracked/60} Hours #{time_tracked % 60} Minutes'
        },"
        total_minutes_tracked += time_tracked
    end

    time_tracking_report_body = "
      {
        'response_type':'in_channel',
        'text': '*Project Time Tracking Report For #{datestring.titleize }* from <@#{slack_data['user_id']}> \n Total time tracked: *#{total_minutes_tracked/60} Hours #{total_minutes_tracked % 60} Minutes*',
        'attachments': [#{ return_attatchments[0..-1] }]
      }"
    HTTParty.post(slack_data['response_url'], body: time_tracking_report_body)
  end
end
