require 'net/http'
require 'json'
require 'slack-ruby-client'
require 'pp'
# require 'sinatra'
require 'httparty'

def get_json_url_with_params(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  res = Net::HTTP.get_response(uri)
  response_body = res.body.to_s
  return JSON.parse(response_body)
end

def better_slack_whos_tracking_callback(slack_data)
  return_attatchments = ""
  reports_response = HTTParty.post(
    "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
    body: {"report_type" => "timetracking", "start_date" => "today" }
  )
  reports_response.each do | entry |
    if entry['tracked'] == nil
      card = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}/cards/#{entry["card_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)

      return_attatchments << "{
        'color': '#36a64f',
        'author_name': '#{entry['user_name']}',
        'author_link': 'https://app.breeze.pm/tasks/board?utf8=%E2%9C%93&users%5B%5D=#{entry['user_id']}',
        'title': '#{card['name']}',
        'title_link': 'https://app.breeze.pm/cards/#{card['id']}/',
        'text': '#{card['project']['name']}'
      },"

      puts entry
      puts card
    end
  end

  if return_attatchments == ""
    return_attatchments = "{ 'color': 'warning', 'title': 'No one is tracking time!' },"
  end
  HTTParty.post(slack_data['response_url'], body: "{'response_type':'in_channel', 'text': '*Current Tracking Report* from <@#{slack_data['user_id']}>', 'attachments': [#{ return_attatchments[0..-1] }] }")
end


return_attatchments = ""
reports_response = HTTParty.post(
  "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
  body: {"report_type" => "timetracking", "start_date" => "today" }
)
reports_response.each do | entry |
  if entry['tracked'] == nil
    puts "https://api.breeze.pm/V2/projects/#{entry["project_id"]}/cards/#{entry["card_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq"
    card = HTTParty.get("https://api.breeze.pm/V2/projects/#{entry["project_id"]}/cards/#{entry["card_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
    project = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}/.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
    pp card
    return_attatchments << "{
      'color': '#36a64f',
      'author_name': '#{entry['user_name']}',
      'author_link': 'https://app.breeze.pm/tasks/board?utf8=%E2%9C%93&users%5B%5D=#{entry['user_id']}',
      'title': '#{card['name']}',
      'title_link': 'https://app.breeze.pm/cards/#{card['id']}/',
      'text': '#{project['name']}'
    },"

    puts entry
    puts card
  end
end
