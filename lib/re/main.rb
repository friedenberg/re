require 'open3'
require 're/validation'

module Re
  module Main
    class << self
      include Re::Validation

      def run(arg)
        unless which(ARGV.first)
          puts "unknown command: #{ARGV.first}"
          exit(1)
        end

        Open3.popen3(ARGV) do |i,o,e,w|
          puts o.read.chomp
        end
      end
    end
  end
end
