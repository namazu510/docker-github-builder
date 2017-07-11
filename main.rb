require 'em-websocket'
require 'json'
require 'open3'

HOST = '0.0.0.0'
PORT = 8888

EM::WebSocket.start({host: HOST , port: PORT}) do |ws_conn|
  ws_conn.onopen do
    puts 'connected'
  end

  ws_conn.onmesage do |message|
    puts "recived message #{message}"
    params = JSON.parse(message)
    param_str = "-r #{params.repo} -t #{params.token} -c #{params.commit_id}"
    Open3.popen3("./image-build #{param_str}") do |i, o, e, w|
      o.each do |line|
        puts line
        ws_conn.send(line)
      end
      e.each do |line|
        puts line
        ws_conn.send(line)
      end
  end

  ws_conn.onerror do |error|
    if error.kind_of?(EM:WebSocket::WebSocketError) do
      p error
    end
  end
end
