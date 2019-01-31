require 'date'
require 'net/http'
require 'json'
require 'pp'
require 'slack-ruby-client'

require 'httparty'

def next_business_day(date)
  skip_weekends(date, 1)
end

def previous_business_day(date)
  skip_weekends(date, -1)
end

def skip_weekends(date, inc = 1)
  date += inc
  while date.wday == 0 || date.wday == 6
    date += inc
  end
  date
end


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
  pp project
end
