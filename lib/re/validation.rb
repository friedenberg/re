
module Re
  module Validation
    class << self
      # Cross-platform way of finding an executable in the $PATH.
      # #
      # #   which('ruby') #=> /usr/bin/ruby
      def which(cmd)
        #checks for nil and emptiness
        if cmd.to_s.empty?
          raise ArgumentError.new("Command is empty")
        end

        if cmd.include?(' ')
          raise ArgumentError.new("Command \"#{cmd}\" contains spaces")
        end

        exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
        ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
          exts.each { |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) &&
              !File.directory?(exe)
          }
        end
        return nil
      end
    end
  end
end
