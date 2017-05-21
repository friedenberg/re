require "re/version"
require "re/validation"
require "re/options"

module Re
  class << self
    def run(arg, exec_type = ::Options::ExecType::MODULE)
      case exec_type
      end

      unless Validation::which(arg.first)
        puts "unknown command: #{arg.first}"
        exit(1)
      end

      Open3.popen3(arg) do |i,o,e,w|
        puts o.read.chomp
      end
    end
  end
end
