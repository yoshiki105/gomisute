class LinebotController < ApplicationController
  def callback
    @linebot = Linebot.new(request: request)
    @linebot.respond_to_user

    head :ok
  end
end
