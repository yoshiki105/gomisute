require File.expand_path(File.dirname(__FILE__) + "/environment")
rails_env = ENV['RAILS_ENV'] || :development
set :environment, rails_env
set :output, "#{Rails.root}/log/cron.log"

# 毎朝6時にゴミ捨ての通知をする
every 1.day, at: '6:00 am' do
  rake "trash:check_today"
end
