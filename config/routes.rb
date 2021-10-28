Rails.application.routes.draw do
  post '/callback', to: 'linebot#callback'
end
