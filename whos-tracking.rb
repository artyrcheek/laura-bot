module WhosTracking

end
module WhosTrackingCallback
  def self.slack_reply(slack_data)
    reports_response = HTTParty.post(
      "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
      body: {"report_type" => "timetracking", "start_date" => "today" }
    )
    return_attatchments = ""
    reports_response.each do | entry |
      if entry['tracked'] == nil
        card = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}/cards/#{entry["card_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
        project = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
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
    HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text': '*Current Tracking Report* from <@#{slack_data['user_id']}>', 'attachments': [#{ return_attatchments[0..-1] }] }")
  end
end
