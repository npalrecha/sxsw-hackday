require './web'

ENV['RACK_ENV'] ||= 'development' # Default to development

run Sinatra::Application

