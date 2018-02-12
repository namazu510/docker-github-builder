require 'em-websocket'
require 'json'
require 'open3'
require 'digest/md5'

require './build_info.rb'

HOST = ENV['HOST'] || '0.0.0.0'
PORT = ENV['PORT'] || 8888
DOCKER_REG = ENV['DOCKER_REG'] || 'localhost'

# FIXME: このコードはゴミコードに近づきつつある。　何とかしてほしい
EM::WebSocket.start({host: HOST , port: PORT}) do |ws_conn|
  ws_conn.onopen do
    puts 'connected'
  end

  ws_conn.onmessage do |message|
    puts "recived message #{message}"
    params = JSON.parse(message)
    build_info = BuildInfo.new(params)
    clone_dir = build_info.clone_dir
    repo_uri = build_info.repo_uri
    clone_cmd = build_info.clone_cmd

    cmd_handler = Proc.new do |i, o, e, w|
      i.close
      o.each do |line|
        puts line
        ws_conn.send(JSON.generate({type: 'log', data: line}))
      end
      e.each do |line|
        puts line
        ws_conn.send(JSON.generate({type: 'err_log', data: line}))
      end
      w.value.to_i
    end

    # GIT CLONE
    `mkdir repo`
    `rm -rf #{clone_dir}`
    ws_conn.send(JSON.generate({type: 'start', data: params}))
    status = Open3.popen3("#{clone_cmd} #{clone_dir}", &cmd_handler)
    if status != 0
      ws_conn.close
    end


    # CHECKOUT
    if params['commit_id']
      status = Open3.popen3("cd #{clone_dir} && git checkout #{params['commit_id']}", &cmd_handler)
      if status != 0
        ws_conn.close
      end
    end

    # BUILD & PUSH
    commit_id = `cd #{clone_dir} && git show -s --format=%H` # ビルドするコミットID
    docker_tag = "#{DOCKER_REG}/#{repo_uri.downcase}:#{commit_id}"

    state = Open3.popen3("cd #{clone_dir} && docker build . -t #{docker_tag}", &cmd_handler)
    if state != 0
      ws_conn.send(JSON.generate({type: 'exit', data:
          { code: state, repo_url: docker_tag, commit_id: commit_id}}))
      ws_conn.close
    end

    state = Open3.popen3("docker push #{docker_tag}", &cmd_handler)
    ws_conn.send(JSON.generate({type: 'exit', data:
        { code: state, repo_url: docker_tag, commit_id: commit_id}}))
  end

  ws_conn.onclose do
    puts 'closed'
  end

  ws_conn.onerror do |error|
    p error
  end
end
