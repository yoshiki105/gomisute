require 'line/bot'

class LinebotController < ApplicationController
  # before_action :set_line, only: [:show, :edit, :update, :destroy]
  # protect_from_forgery with: :null_session

  def callback
    client ||= Line::Bot::Client.new { |config|
      config.channel_id = ENV["LINE_CHANNEL_ID"]
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }

    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          response = if event.message['text'].include?('こんにちは')
              'こんにちは！'
            elsif event.message['text'].include?('こんにちは')
              'よろしく！'
            else
              'よくわかりません。'
            end
          message = {
            type: 'text',
            text: response
          }
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          File.binwrite("/myapp/public/hogehoge.jpg", response.body)
          message = {
            type: 'image',
            originalContentUrl: "https://yourdomain/hogehoge.jpg",
            previewImageUrl: "https://yourdomain/hogehoge.jpg"
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end
end
