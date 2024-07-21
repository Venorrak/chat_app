require 'bundler/inline'
require 'awesome_print'
require "openssl"
require "json"
require 'email_address_validator'

gemfile do
  source 'https://rubygems.org'
  gem 'mysql2'
  gem "sinatra-contrib"
  gem "rackup"
  gem "webrick"
end
require 'mysql2'
require 'sinatra'

set :port, 3333
set :bind, '0.0.0.0'

$SQLclient = Mysql2::Client.new(:host => "localhost", :username => "chat", :password => "jsp")
$SQLclient.query("USE chat_app;")

get '/' do
  return send_file "html/chat.html"
end

get '/signup' do
  return send_file "html/signup.html"
end

get '/style.css' do
  return send_file "style.css"
end

post '/signup' do
  data = JSON.parse(request.body.read)
  userList = $SQLclient.query("SELECT email, username FROM users;")
  if userList.any? { |user| user["email"] == data["email"] }
    return [
      401,
      { "Content-Type" => "application/json" },
      [{ "error" => "Email already in use" }.to_json]
    ]
  end
  if EmailAddressValidator.validate_addr(data["email"], true) != true
    return [
      401,
      { "Content-Type" => "application/json" },
      { "error" => "Invalid email" }.to_json
    ]
  end
  if userList.any? { |user| user["username"] == data["username"] }
    return [
      401,
      { "Content-Type" => "application/json" },
      { "error" => "Username already in use" }.to_json
    ]
  end
  p data["email"]
  $SQLclient.query(`INSERT INTO users (username, email, password) VALUES ("#{data["username"]}", "#{data["email"]}", "#{data["password"]}");`)
  return [
    200,
    { "Content-Type" => "application/json" },
    { "message" => "User created" }.to_json
  ]
end

get '/messages' do
  messages = $SQLclient.query("SELECT messages.message, messages.created_at, users.username FROM messages join users on messages.user_id = users.id ORDER BY created_at DESC LIMIT 100;")
  return [
    200,
    { "Content-Type" => "application/json" },
    messages.to_a.to_json
  ]

end

get '/js/chat.js' do
  return send_file "js/chat.js"
end

get '/js/signup.js' do
  return send_file "js/signup.js"
end

Thread.start do
  loop do
    sleep(3600)
    $SQLclient.query("SELECT 1;")
  end
end