require 'sinatra'
require "sinatra/activerecord"
require 'delayed_job_active_record'
require 'awesm'
require 'aws-sdk'

AWS.config(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
)

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL']) if ENV['DATABASE_URL']

set :root, File.dirname(__FILE__)
set :public_folder, "#{File.dirname(__FILE__)}/public"

class Sentence < ActiveRecord::Base
  after_create :generate!

  def ready?
    self.state == 0 ? false : true
  end

  def url
    "http://sentenceshare.s3.amazonaws.com/sentences/#{id}.jpg"
  end

  def generate!
    # take screenshot and push up to s3
    tmp = Tempfile.new(['screenshot', '.jpg'])
    wkhtmltoimage = (/darwin/ =~ RUBY_PLATFORM) != nil ? "wkhtmltoimage" : "wkhtmltoimage-amd64"
    command = "#{File.join([Sinatra::Application.settings.root, "vendor/bin", wkhtmltoimage])} \
               --width 500 \
               'http://sentenceshare.beatsmusic.com/mockup?where=#{where}&what=#{what}&who=#{who}&artist=#{artist}' \
               #{tmp.path}"
    system command
    bucket_name = "sentenceshare"
    file_name = "sentences/#{id}.jpg"
    s3 = AWS::S3.new
    s3.buckets[bucket_name].objects[file_name].write(:file => tmp.path)
    update_attribute(:state, 1)
    tmp.close
    tmp.unlink
  end
end

get '/' do
  erb :"index.html"
end

get '/mockup' do
  erb :"sentence_card.html"
end

get '/card' do
  @sentence = Sentence.where({where: params[:where],
                              what: params[:what],
                              who: params[:who],
                              artist: params[:artist]}).first_or_create!
  if @sentence.ready?
    redirect "https://twitter.com/home?status=#{request.base_url}/card/#{@sentence.id}"
  else
    erb :"poll_card.html"
  end
end

get '/card/:id' do
  @sentence = Sentence.find(params[:id])
  erb :"index.html"
end
