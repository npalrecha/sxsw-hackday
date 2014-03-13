require 'sinatra'
require "sinatra/activerecord"
require 'delayed_job_active_record'
require 'awesm'

set :public_folder, "#{File.dirname(__FILE__)}/public"

class Sentence < ActiveRecord::Base
end

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
  params[:where] = "at SXSW"
  params[:what] = "Partying"
  params[:who] = "My Friends"
  params[:artist] = "Vampire Weekend"

  erb :"sentence_card.html"
end
