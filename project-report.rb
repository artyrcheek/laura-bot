require 'date'
require 'net/http'
require 'json'
require 'pp'
require 'slack-ruby-client'

require 'httparty'

API_TOKEN = "B7ULqZ4WueSY-uv-yCZq"

module ProjectReport

  def self.get_reports_response
    reports_response = HTTParty.post(
      "https://api.breeze.pm/reports?api_token=#{API_TOKEN}",
      body: {"report_type" => "timetracking", "start_date" => "last_week"}
    )
    reports_response
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

  def self.get_name_time_hash
    reports_response = self.get_reports_response()
    id_time_hash = self.parse_reports_to_id_time_hash(reports_response)
    name_time_hash = self.parse_id_time_hash_to_name_time_hash(id_time_hash)
    name_time_hash
  end

end

module ProjectReportCallback
  def self.slack_reply (slack_data)
    # Parsing start date test in slack text
    slack_text = slack_data['text'].strip

    project_name_time_hash = ProjectReport.get_name_time_hash

    return_attatchments = ""
    project_name_time_hash = userMap.sort_by{ |k, v| v }.reverse
    total_minutes_tracked = 0

    project_name_time_hash.each do |project_name, time_tracked|
      return_attatchments << "
        {
          'color': 'good',
          'title': '#{project_name}',
          'text': '#{time_tracked/60} Hours #{time_tracked % 60} Minutes'
        },"
    end

    time_tracking_report_body = "
      {
        'response_type':'in_channel',
        'text': '*Project Time Tracking Report For This Week* from <@#{slack_data['user_id']}> \n Total time tracked: *#{total_minutes_tracked/60} Hours #{total_minutes_tracked % 60} Minutes*',
        'attachments': [#{ return_attatchments[0..-1] }]
      }"
    HTTParty.post(slack_data['response_url'], body: time_tracking_report_body)
  end
end
