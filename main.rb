require 'em-websocket'
require 'json'
require 'open3'
require 'digest/md5'

require './open3_ext.rb'
require './build_info.rb'

HOST = ENV['HOST'] || '0.0.0.0'
PORT = ENV['PORT'] || 8888
DOCKER_REG = ENV['DOCKER_REG'] || 'localhost'

EM::WebSocket.start({host: HOST , port: PORT}) do |ws_conn|
  ws_conn.onopen do
    puts 'connected'
  end

  ws_conn.onmessage do |message|
    puts "recived message #{message}"
    params = JSON.parse(message)
    ws_conn.send(JSON.generate({type: 'start', data: params}))
    build = BuildInfo.new(params)

    # GIT CLONE
    `mkdir repo`
    `rm -rf #{build.clone_dir}`
    Open3.popen3_with_ws("#{build.clone_cmd} #{build.clone_dir}", ws_conn) do |status|
      return ws_conn.close if status != 0
    end

    # CHECKOUT
    if build.commit_id
      Open3.popen3_with_ws("cd #{build.clone_dir} && git checkout #{build.commit_id}", ws_conn) do |status|
        return ws_conn.close if status != 0
      end
    end

    # BUILD
    commit_id = `cd #{build.clone_dir} && git show -s --format=%H` # ビルドするコミットID
    docker_tag = "#{DOCKER_REG}/#{build.repo_uri.downcase}:#{commit_id}"
    Open3.popen3_with_ws("cd #{build.clone_dir} && docker build . -t #{docker_tag}", ws_conn) do |state|
      if state != 0
        ws_conn.send(JSON.generate({type: 'exit', data:
            { code: state, repo_url: docker_tag, commit_id: commit_id}}))
        ws_conn.close
        return
      end
    end

    # PUSH
    Open3.popen3_with_ws("docker push #{docker_tag}", ws_conn) do |state|
      ws_conn.send(JSON.generate({type: 'exit', data:
          { code: state, repo_url: docker_tag, commit_id: commit_id}}))
    end
  end

  ws_conn.onclose do
    puts 'closed'
  end

  ws_conn.onerror do |error|
    p error
  end
end
