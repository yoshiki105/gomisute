class LinebotController < ApplicationController
  def callback
    respond_to_user
  end
end
