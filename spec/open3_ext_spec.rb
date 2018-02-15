require './open3_ext.rb'
require 'thread'

RSpec.describe Open3Ext do
  before :each do
    @ws = double('WebSocketConnection')
    # Queueはスレッドセーフ, Arrayはダメ
    # Arrayのがeq検証しやすいのでto_aを実装する
    @logs = Queue.new
    @logs.send(:define_singleton_method, :to_a) do
      cnt = size
      res = []
      cnt.times do
        obj = pop
        res.push(obj)
        push(obj)
      end
      res
    end
    allow(@ws).to receive(:send) do |str|
      @logs.push(str)
    end
  end

  it 'コマンドの実行結果が取れること' do
    cmd = "echo 'hello'"
    Open3.popen3_with_ws(cmd, @ws)
    expect(@logs.to_a).to eq [JSON.generate(type: 'log', data: "hello\n")]
  end

  it 'エラーも正しくとれること' do
    cmd = "echo 'hello' >&2"
    Open3.popen3_with_ws(cmd, @ws)
    expect(@logs.to_a).to eq [JSON.generate(type: 'err_log', data: "hello\n")]
  end

  it '正しい順番で出てくること' do
    cmd = "echo 'hello' ; echo 'hello'>&2 ; echo 'hello'"
    Open3.popen3_with_ws(cmd, @ws)
    expect(@logs.to_a).to eq [
      JSON.generate(type: 'log', data: "hello\n"),
      JSON.generate(type: 'err_log', data: "hello\n"),
      JSON.generate(type: 'log', data: "hello\n")
    ]
  end

  it 'リアルタイムに出てくること' do
    cmd = "echo 'hello' ; sleep 5 ; echo 'hello'"
    Thread.new do
      Open3.popen3_with_ws(cmd, @ws)
    end

    sleep 1
    puts "check-1"
    expect(@logs.to_a).to eq [JSON.generate(type: 'log', data: "hello\n")]

    sleep 2
    puts "check-2"
    expect(@logs.to_a).to eq [JSON.generate(type: 'log', data: "hello\n")]

    sleep 3
    puts "check-3"
    expect(@logs.to_a).to eq [
      JSON.generate(type: 'log', data: "hello\n"),
      JSON.generate(type: 'log', data: "hello\n")
    ]
  end

  it 'ブロックが実行されること' do
    res = 1 # Non Zero
    cmd = ':' # Status Code => 0
    Open3.popen3_with_ws(cmd, @ws) do |status|
      res = status
    end
    expect(res).to eq 0
  end

  it '失敗時のブロック引数が反映されること' do
    res = 0 # Zero
    cmd = 'git klone git@mofumofu.net:kulu/shippo.git' # Status Code != 0
    Open3.popen3_with_ws(cmd, @ws) do |status|
      res = status
    end
    expect(res).not_to eq 0
  end
end