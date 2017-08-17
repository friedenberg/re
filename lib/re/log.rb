
module Re
  module Log
    def self.l(s, stream: STDOUT)
      stream.puts "#{get_thread_name}: #{s}" if $verbose
    end

    def self.d(s)
      l(s, stream: STDERR)
    end

    protected

    def self.get_thread_name
      Thread.current[:name] || "main"
      ""
    end
  end
end
