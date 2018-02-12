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

    # GIT CLONE
    puts "try : mkdir repo"
    puts "try : rm -rf #{clone_dir}"

    if clone_cmd.empty? || clone_dir.empty? || repo_uri.empty?
      puts "invalid paramater"
      ws_conn.send(JSON.generate({type: 'err_log', data: 'invalid git repository parameter'}))
      ws_conn.close
    end

    ws_conn.send(JSON.generate({type: 'start', data: params}))

    puts "try : #{clone_cmd} #{clone_dir}"
    10.times do |i|
      line = "git clone #{i}"
      ws_conn.send(JSON.generate({type: 'err_log', data: line + ' err'}))
      ws_conn.send(JSON.generate({type: 'log', data: line}))
    end


    # CHECKOUT
    if params['commit_id']
      _, e, s = Open3.capture3("cd #{clone_dir} && git checkout #{params['commit_id']}")
      puts "try git checkout #{params['commit_id']}"
    end

    # BUILD & PUSH
    puts "try : cd #{clone_dir} && git show -s --format=%H"
    commit_id = 'test'
    docker_tag = "#{DOCKER_REG}/#{repo_uri.downcase}:#{commit_id}"

    puts "try : docker build . -t #{docker_tag} && docker push #{docker_tag}"
    20.times do |i|
      line = "docker build #{i}"
      ws_conn.send(JSON.generate({type: 'err_log', data: line + ' err'}))
      ws_conn.send(JSON.generate({type: 'log', data: line}))
    end

    ws_conn.send(JSON.generate({type: 'exit', data: {
        code: 0,
        repo_url: docker_tag,
        commit_id: commit_id
    }}))
  end

  ws_conn.onclose do
    puts 'closed'
  end

  ws_conn.onerror do |error|
    p error
  end
end
