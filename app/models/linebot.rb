require 'line/bot'
include LinebotEvent

def respond_to_user
  body = request.body.read
  validate_client_signature(body)

  events = client.parse_events_from(body)
  events.each do |event|
    main_action(event)
  end
  head :ok
end
