require 'digest/md5'

class BuildInfo
  def initialize(params)
    @params = params
    @type ||= :github if @params['token']
    @type ||= :http if @params['repo'].start_with? 'http'
    @type ||= :ssh
    fail "invalid parameter" if send("#{@type}_valid?")
    send("#{@type}_parse").each do |k, v|
      define_singleton_method(k) { v }
    end
  end

  def github_valid?
    # TODO: 正規表現でパラメータをチェックする
  end

  def github_parse
    user = @params['repo'].split('/')[0]
    repo = @params['repo'].split('/')[1]
    {
        repo_uri: "#{user}/#{repo}",
        clone_cmd: "git clone https://#{user}:#{@params['token']}@github.com/#{user}/#{repo}",
        clone_dir: "repos/git@github.com/#{user}/#{repo}"
    }
  end

  def http_valid?
    # TODO: 正規表現でパラメータをチェックする
  end

  def http_parse
    m = @params['repo'].match(/^https?:\/\/([^\/]+)\/(.+)\.git$/)
    {
        repo_uri: m[2],
        clone_dir: "repos/git@#{m[1]}/#{m[2]}",
        clone_cmd: "git clone #{@params['repo']}"
    }
  end

  def ssh_valid?
    # TODO: 正規表現でパラメータをチェックする
  end

  def ssh_parse
    m = @params['repo'].match(/^([a-z_][a-z0-9_]{0,30}@.+):\/?(.+)\.git$/)

    repo_uri = m[2]
    clone_dir = "repos/#{m[1]}/#{repo_uri}"

    clone_cmd = "git clone #{@params['repo']}"
    if @params['key']
      `mkdir -p keys`
      filename = "keys/#{Digest::MD5.hexdigest(@params['key'])}"
      File.open(filename, 'w') do |f|
        f.puts params['key']
      end
      clone_cmd = "GIT_SSH_COMMAND='ssh -i #{filename} -F /dev/null' " + clone_cmd
    end

    {
        repo_uri: repo_uri,
        clone_dir: clone_dir,
        clone_cmd: clone_cmd
    }
  end
end