require 'sinatra'
require "sinatra/activerecord"
require 'delayed_job_active_record'
require 'awesm'

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')

set :root, File.dirname(__FILE__)
set :public_folder, "#{File.dirname(__FILE__)}/public"

class Sentence < ActiveRecord::Base

  def generate!
    # take screenshot and push up to s3
    tmp = Tempfile.new('screenshot')
    wkhtmltoimage = (/darwin/ =~ RUBY_PLATFORM) != nil ? "wkhtmltoimage" : "wkhtmltoimage-amd64"
    system "#{File.join([settings.root, "vendor/bin", wkhtmltoimage])} #{url("/card")} #{tmp.path}"
    tmp.close
    tmp.unlink
  end
end

get '/' do
  "Front Page / backbone app to create sentence #{settings.root}"
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
