API_TOKEN = "B7ULqZ4WueSY-uv-yCZq"

module WhosTracking
  def self.get_reports_response
    reports_response = HTTParty.post(
      "https://api.breeze.pm/reports?api_token=#{API_TOKEN}",
      body: {"report_type" => "timetracking", "start_date" => "today" }
    )
    reports_response
  end
  def self.get_return_attatchments(reports_response)
    return_attatchments = ""
    reports_response.each do | entry |
      if entry['tracked'] == nil
        card = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}/cards/#{entry["card_id"]}.json?api_token=#{API_TOKEN}",)
        project = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}.json?api_token=#{API_TOKEN}",)
        better_entry = card['time_entries'].select do |newentry| newentry['id'] == entry['id'] end[0]
        return_attatchments << "{
          'color': 'good',
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
    return_attatchments
  end
end
module WhosTrackingCallback
  def self.slack_reply(slack_data)
    reports_response = WhosTracking.get_reports_response
    return_attatchments = WhosTracking.get_return_attatchments(reports_response)
    HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text': '*Current Tracking Report* from <@#{slack_data['user_id']}>', 'attachments': [#{ return_attatchments[0..-1] }] }")
  end
end
