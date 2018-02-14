require 'open3'
require 'json'

module Open3Ext
  def popen3_with_ws(cmd, ws)
    state = Open3.popen3(cmd) do |i, o, e, w|
      i.close
      begin
        files = [o, e]
        error_file = e.fileno
        until files.empty? do
          ready = IO.select(files)
          if ready
            readable = ready[0]
            readable.each do |f|
              begin
                line = f.readline
                is_err = f.fileno == error_file

                puts line
                if is_err
                  ws.send(JSON.generate({type: 'err_log', data: line}))
                else
                  ws.send(JSON.generate({type: 'log', data: line}))
                end
              rescue EOFError => e
                files.delete f
              end
            end
          end
        end
      end
      w.value.to_i
    end
    yield(state) if block_given?
  end
end

module Open3
  class << self
    prepend Open3Ext
  end
end