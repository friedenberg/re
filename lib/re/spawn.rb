
module Re
  class Spawn
    def self.by_line(command)
      if command.to_s.empty?
        raise ArgumentError.new('Empty command')
      end

      stderr, wstderr = IO.pipe
      stdout, wstdout = IO.pipe

      pid = spawn(
        command,
        :in  => :close,
        :out => wstdout,
        :err => wstderr,
      )

      runner = Thread.new do
        while line = stdout.gets
          yield line
        end
      end

      Process.wait(pid)

      wstderr.close
      wstdout.close

      runner.join

      return [$?, stderr.read]
    rescue => e
      return [1, e.message]
    ensure
      stdout.close unless stdout.nil?
      stderr.close unless stderr.nil?
    end

    def self.stdout(command)
      acc = []

      process, stderr = self.by_line(command) do |line|
        acc << line
      end

      #todo offer stderr less destructively
      if process.exitstatus != 0 or not stderr.empty?
        raise stderr
      end

      acc.join("\n")
    end
  end
end
