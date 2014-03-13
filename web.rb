require 'sinatra'
require "sinatra/activerecord"
require 'delayed_job_active_record'
require 'aws-sdk'
require 'oauth'
require 'twitter'
require 'open-uri'

CONSUMER_KEY=ENV['TWITTER_CONSUMER_KEY']
CONSUMER_SECRET=ENV['TWITTER_CONSUMER_SECRET']

if(ENV['RACK_ENV'] == "production")
  CALLBACK_URL="http://sentenceshare.beatsmusic.com/oauth/callback"
else
  CALLBACK_URL="http://localhost:5000/oauth/callback"
end

AWS.config(
  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
)

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL']) if ENV['DATABASE_URL']

enable :sessions

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

  def twitter_share_url
    "http://api.awe.sm/url/share?channel=twitter&v=3&key=9bd1f65e737d8ec56d4684791b60cc6499f2e77d2820fe06c8b9c8181d95bdc2&tool=sbOpxg&url=http%3A%2F%2Fsentenceshare.beatsmusic.com/card/#{id}&destination=http%3A%2F%2Ftwitter.com%2Fshare%3Ftext%3DI+just+made+my+own+%2523BeatsSentence+for+%2523sxsw.+Make+yours+at%26url%3DAWESM_URL&campaign=sxsw-hackday"
  end

  def generate!
    # take screenshot and push up to s3
    tmp = Tempfile.new(['screenshot', '.jpg'])
    wkhtmltoimage = (/darwin/ =~ RUBY_PLATFORM) != nil ? "wkhtmltoimage" : "wkhtmltoimage-amd64"
    command = "#{File.join([Sinatra::Application.settings.root, "vendor/bin", wkhtmltoimage])} \
               --width 678 \
               --quality 100 \
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
    session[:sentence_id] = @sentence.id
    session[:status] = params[:status] || "I just made my own #BeatsSentence for #sxsw. Make yours at http://sentenceshare.beatsmusic.com"
    redirect '/oauth/request_token'
  else
    erb :"poll_card.html"
  end
end

get '/card/:id' do
  @sentence = Sentence.find(params[:id])
  erb :"index.html"
end


### Twitter stuff ###
get '/oauth/request_token' do
  consumer = OAuth::Consumer.new CONSUMER_KEY, CONSUMER_SECRET, :site => 'https://api.twitter.com'

  request_token = consumer.get_request_token :oauth_callback => CALLBACK_URL
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret

  puts "request: #{session[:request_token]}, #{session[:request_token_secret]}"

  redirect request_token.authorize_url
end

get '/oauth/callback' do
  @sentence = Sentence.find(session[:sentence_id])
  status = session[:status]

  consumer = OAuth::Consumer.new CONSUMER_KEY, CONSUMER_SECRET, :site => 'https://api.twitter.com'

  puts "CALLBACK: request: #{session[:request_token]}, #{session[:request_token_secret]}"

  request_token = OAuth::RequestToken.new consumer, session[:request_token], session[:request_token_secret]
  access_token = request_token.get_access_token :oauth_verifier => params[:oauth_verifier]

  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = CONSUMER_KEY
    config.consumer_secret     = CONSUMER_SECRET
    config.access_token        = access_token.token
    config.access_token_secret = access_token.secret
  end

  update = client.update_with_media(status, open(@sentence.url))
  redirect update.url
end

