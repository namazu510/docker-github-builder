require 'em-websocket'
require 'json'
require 'open3'

HOST = '0.0.0.0'
PORT = 8888

EM::WebSocket.start({host: HOST , port: PORT}) do |ws_conn|
  ws_conn.onopen do
    puts 'connected'
  end

  ws_conn.onmessage do |message|
    puts "recived message #{message}"
    params = JSON.parse(message)
    cmd  = "./image-build -r #{params.repo} -t #{params.token} -c #{params.commit_id}"

    ws_conn.send(JSON.generate({type: "start", data: params}))
    Open3.popen3(cmd) do |i, o, e, w|
      i.close
      o.each do |line|
        puts line
        ws_conn.send(JSON.generate({type: "log", data: line}))
      end
      e.each do |line|
        puts line
        ws_conn.send(JSON.generate({type: "err_log", data: line}))
      end

      ws_conn.send(JSON.generate({
        type: "exit",
        data: {
          code: w.value.exit
        }
      }))
    end
  end

  ws_conn.onclose do
    puts "closed"
  end

  ws_conn.onerror do |error|
    p error
  end
end
