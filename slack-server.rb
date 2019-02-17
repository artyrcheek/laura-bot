require 'net/http'
require 'json'
require 'slack-ruby-client'
require 'sinatra'
require 'httparty'

require "./project-report"
require "./whos-tracking"
require "./report"

post "/whostracking" do
  content_type :json
  status 200
  slack_data = request.POST
  Thread.new do
    begin
      WhosTrackingCallback.slack_reply(slack_data)
    rescue
      error_response = "{'text': 'Sorry, something went wrong before trying to read breeze'}"
      HTTParty.post(slack_data['response_url'], body: error_response)
    end
  end
  return "one minute, scanning breeze"
end

post "/report" do
  content_type :json
  status 200
  slack_data = request.POST
  if slack_data["text"].include? "help"
    return "{'text': 'please include a timeframe after `/report`, you can use `today`, `yesterday`, `this_week`, `this_month`, `last_week`, `last_month` or leave blank for the last workday also add `detailed` to see what projects each person has worked on'}"
  end
  Thread.new do
    begin
      ReportCallback.slack_reply(slack_data)
    rescue
      error_response = "{'text': 'Sorry, something went wrong before trying to scan breeze reports'}"
      HTTParty.post(slack_data['response_url'], body: error_response)
    end
  end
  return "Getting Report data"
end

post "/projectreport" do
  content_type :json
  status 200
  slack_data = request.POST
  if slack_data["text"].include? "help"
    return "{'text': 'please include a timeframe after `/projectreport`, you can use `today`, `yesterday`, `this_week`, `this_month`, `last_week`, `last_month` or leave blank for the last workday'}"
  end
  Thread.new do
    begin
      ProjectReportCallback.slack_reply(slack_data)
    rescue
      error_response = "{'text': 'Sorry, something went wrong before trying to scan breeze project reports'}"
      HTTParty.post(slack_data['response_url'], body: error_response)
    end
  end
  return "Getting Project Report data"
end
