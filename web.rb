require 'sinatra'

set :public_folder, "#{File.dirname(__FILE__)}/public"

get '/' do
  "Front Page / backbone app to create sentence"
end

get '/card' do
  # This endpoint dynamically generates the card (this is what we make the image from)
  erb :"sentence_card.html"
end

get '/card/:slug' do
  # This is what we link back to from twitter
  # Load existing card from the database
  params[:location] = "at SXSW"
  params[:action] = "Partying"
  params[:with] = "My Friends"
  params[:artist] = "Vampire Weekend"

  erb :"sentence_card.html"
end
