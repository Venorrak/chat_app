require 'bundler/inline'
require 'awesome_print'
require "openssl"
require "json"

gemfile do
  source 'https://rubygems.org'
  gem 'mysql2'
  gem "sinatra-contrib"
  gem "rackup"
  gem "webrick"
end
require 'mysql2'
require 'sinatra'

set :port, 6666
set :bind, '0.0.0.0'

$SQLclient = Mysql2::Client.new(:host => "localhost", :username => "chat", :password => "jsp")
$SQLclient.query("USE chat_app;")

get '/' do
  return send_file "html/chat.html"
end

get '/signup' do
  return send_file "html/signup.html"
end

post '/signup' do
  #
end

Thread.start do
  loop do
    sleep(3600)
    $SQLclient.query("SELECT 1;")
  end
end