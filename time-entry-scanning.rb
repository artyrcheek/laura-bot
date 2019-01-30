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

return_attatchments = ""
reports_response = HTTParty.post(
  "https://api.breeze.pm/reports?api_token=B7ULqZ4WueSY-uv-yCZq",
  body: {"report_type" => "timetracking", "start_date" => "today" }
)
reports_response.each do | entry |
  if entry['tracked'] == nil
    card = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}/cards/#{entry["card_id"]}.json?api_token=B7ULqZ4WueSY-uv-yCZq",)
    project = HTTParty.get("https://api.breeze.pm/projects/#{entry["project_id"]}/.json?api_token=B7ULqZ4WueSY-uv-yCZq",)

    return_attatchments << "{
      'color': '#36a64f',
      'author_name': '#{entry['user_name']}',
      'author_link': 'https://app.breeze.pm/tasks/board?utf8=%E2%9C%93&users%5B%5D=#{entry['user_id']}',
      'title': '#{card['name']}',
      'title_link': 'https://app.breeze.pm/cards/#{card['id']}/',
      'text': '#{project['name']}'
    },"
  end
end

if return_attatchments == ""
  return_attatchments = "{ 'color': 'warning', 'title': 'No one is tracking time!' },"
end
