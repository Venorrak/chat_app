require 'bundler/inline'
require 'websocket-eventmachine-server'
require 'json'
require 'awesome_print'
$clients = []

gemfile do
  source 'https://rubygems.org'
  gem 'mysql2'
end
require 'mysql2'

$SQLclient = Mysql2::Client.new(:host => "localhost", :username => "chat", :password => "jsp")
$SQLclient.query("USE chat_app;")

def treatMessage(message, sender)
  # var obj = {
  #     type: "message",
  #     data: message,
  #     tempId: tempId
  # };
  # var obj = {
  #     type: "auth",
  #     data: {
  #         username: username,
  #         password: password
  #     }
  # };
  client = getClientBySocket(sender)
  message = JSON.parse(message)
  case message["type"]
  when "auth"
    authenticateClient(message["data"], sender)
  when "message"
    if client["authenticated"]
      sendToAll(message["data"], sender, message["tempId"])
    end
  end
end

def authenticateClient(data, socket)
  client = getClientBySocket(socket)
  list = $SQLclient.query("SELECT username, password, id FROM users;")
  if list.any? { |user| user["username"] == data["username"] && user["password"] == data["password"] }
    setClientValue(socket, "username", data["username"])
    setClientValue(socket, "authenticated", true)
    clientId = list.find { |user| user["username"] == data["username"] }["id"]
    setClientValue(socket, "user_id", clientId)
    client["socket"].send({ "type" => "auth", "data" => "success", "username" => data["username"] }.to_json)
  else
    client["socket"].send({ "type" => "auth", "data" => "fail", "username" => data["username"] }.to_json)
  end
end

def sendToAll(message, sender, tempMessageId = nil)
  messageId = SecureRandom.alphanumeric(10)
  senderName = getClientBySocket(sender)["username"]
  messageTime = getTime()
  begin
    $SQLclient.query(`INSERT INTO messages (user_id, message, created_at) VALUES (#{getClientBySocket(sender)["user_id"]}, "#{message}", '#{messageTime}');`)
  rescue => exception 
    puts exception
    $SQLclient.query("INSERT INTO messages (user_id, message, created_at) VALUES (#{getClientBySocket(sender)["user_id"]}, 'this person messed with the database in some way idk', '#{messageTime}');")
  end
  $clients.each do |client|
    if client["socket"] != sender
      client["socket"].send({"type" => "message", "data" => message, "username" => senderName, "timestamp" => messageTime, "id" => messageId}.to_json)
    else
      client["socket"].send({"type" => "confirm", "timestamp" => messageTime, "id" => messageId, "tempId" => tempMessageId}.to_json)
    end
  end
end

def getTime()
  Time.now.strftime("%Y-%m-%d %H:%M:%S")
end

def getClientBySocket(socket)
  $clients.find { |client| client["socket"] == socket }
end

def setClientValue(socket, key, value)
  client = $clients.find { |client| client["socket"] == socket }
  index = $clients.find_index(client)
  client[key] = value
  $clients[index] = client
end

def createClient(socket)
  client = {
    "socket" => socket,
    "username" => nil,
    "user_id" => nil,
    "last_ping" => getTime(),
    "authenticated" => false
  }
  $clients << client
end

def removeClient(socket)
  $clients.delete_if { |client| client["socket"] == socket }
end

EM.run do
  WebSocket::EventMachine::Server.start(:host => "0.0.0.0", :port => 2345) do |ws|
    ws.onopen do
      createClient(ws)
    end

    ws.onmessage do |msg|
      treatMessage(msg, ws)
    end

    ws.onclose do
      removeClient(ws)
      ws.close
    end

    ws.onerror do |error|
      puts "Error: #{error}"
    end

    ws.onping do |message|
      setClientValue(ws, "last_ping", getTime())
      ws.pong("pong")
    end

  end
end

Thread.start do
  loop do
    sleep(3600)
    $SQLclient.query("SELECT 1;")
  end
end
