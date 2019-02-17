require 'date'
require 'net/http'
require 'json'
require 'pp'
require 'slack-ruby-client'

require 'httparty'

require "./project-report"

ProjectReportCallback.slack_reply({"text" => "empty", "user_id" => "arty", "response_url" => "nothing" })
