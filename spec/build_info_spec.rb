require './build_info.rb'

RSpec.describe BuildInfo do
  context'SSH形式' do
    it 'パースと取得' do
      info = BuildInfo.new({ 'repo' => 'git@github.com:kulu/mofu.git' })
      expect(info.repo_uri).to eq 'kulu/mofu'
      expect(info.clone_cmd).to eq 'git clone git@github.com:kulu/mofu.git'
      expect(info.clone_dir).to eq 'repos/git@github.com/kulu/mofu'
    end

    it 'keyが付いた場合' do
      file_dst = StringIO.new('', 'w')
      allow(File).to receive(:open).and_yield(file_dst)

      info = BuildInfo.new({
         'repo' => 'git@github.com:kulu/mofu.git',
         'key' => 'ssh-private-key'
      })
      key_name = 'keys/' + Digest::MD5.hexdigest('ssh-private-key')
      # コマンドが正常に組まれること
      expect(info.clone_cmd).to eq "GIT_SSH_COMMAND='ssh -i #{key_name} -F /dev/null' git clone git@github.com:kulu/mofu.git"

      # 鍵が書き出されていること
      expect(file_dst.string).to eq 'ssh-private-key'
    end
  end

  context 'HTTP形式' do
    it 'パースと取得' do
      info = BuildInfo.new({ 'repo' => 'https://github.com/kulu/shippo.git' })
      expect(info.repo_uri).to eq 'kulu/shippo'
      expect(info.clone_cmd).to eq 'git clone https://github.com/kulu/shippo.git'
      expect(info.clone_dir).to eq 'repos/git@github.com/kulu/shippo'
    end
  end

  context 'TOKEN形式' do
    it 'パースと取得' do
      info = BuildInfo.new({
        'repo' => 'kulu/shippo',
        'token' => 'mofumofu'
      })
      expect(info.repo_uri).to eq 'kulu/shippo'
      expect(info.clone_cmd).to eq 'git clone https://kulu:mofumofu@github.com/kulu/shippo'
      expect(info.clone_dir).to eq 'repos/git@github.com/kulu/shippo'
    end
  end
end
