require 'shellwords'
require 're/utility'

module Re
  class Options
    module ExecType
      MODULE              = 1
      EXECUTABLE          = 2
    end

    attr_reader :utility, :transform, :replacement, :max_depth, :raw_output

    def initialize(args)
      @max_depth = 0
      @raw_output = false

      parser = OptionParser.new do |parser|
        parser.accept(Utility) do |arg|
          Utility.new(arg)
        end

        parser.on(
          '-t',
          '--transform [TRANSFORM_UTILITY]',
          Utility,
          'TRANSFORM_UTILITY to use between output at one level and input at another'
        ) do |transform|
          @transform = transform
        end

        parser.on(
          '-I [REPLSTR]',
          String,
          'argument replacement to perform on UTILITY. Also applies to TRANSFORM_UTILITY'
        ) do |replacement|
          @replacement = replacement
        end

        parser.on(
          '-r',
          '--raw-outout',
          'do not use the transform utility for output, only for graph traversal',
        ) do
          @raw_output = true
        end

        parser.on(
          '-d [MAX_DEPTH]',
          '--depth [MAX_DEPTH]',
          Integer,
          'maximum depth to recursively navigate the graph',
        ) do |max_depth|
          @max_depth = max_depth
        end
      end

      first_non_option_found = nil

      options = parser.order!(args) do |a|
        first_non_option_found = a
        parser.terminate
      end

      parse_args(options.unshift(first_non_option_found))
    end

    def parse_args(args)
      @utility = Utility.new(args.shelljoin)
    end
  end
end
