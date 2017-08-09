require 'shellwords'

module Re
  class Utility
    # Cross-platform way of finding an executable in the $PATH.
    # #
    # #   which('ruby') #=> /usr/bin/ruby
    def self.which(cmd)
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

    attr_reader :name, :path

    def initialize(utility)
      if utility.kind_of? Array
        @command = utility.shelljoin
      elsif utility.to_s.empty?
        raise ArgumentError.new("Empty utility")
      else
        @command = utility
      end

      @name = @command.shellsplit.first
      @path = self.class.which(@name)

      if @path.to_s.empty? and File.executable? @name
        @path = File.absolute_path(@name)
      end

      if @path.to_s.empty?
        raise ArgumentError.new("Command #{@name} could not be found in PATH")
      end
    end

    def command(arg = nil, replacement_string = nil)
      if arg.nil?
        @command
      elsif not replacement_string.nil?
        @command.sub(replacement_string, arg)
      else
        @command + ' ' + arg.chomp
      end
    end
  end
end
