class Linebot
  require 'line/bot'
  include ActiveModel::Model
  include LinebotEvent

  attr_accessor :request

  def respond_to_user
    body = request.body.read
    validate_client_signature(body)

    events = client.parse_events_from(body)
    events.each do |event|
      main_action(event)
    end
  end
end
