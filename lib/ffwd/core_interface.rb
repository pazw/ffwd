module FFWD
  class CoreInterface
    attr_reader :input, :output
    attr_reader :tunnel_plugins, :statistics, :debug, :processor_opts
    attr_reader :tags, :attributes

    def initialize input, output, tunnel_plugins, statistics, debug, processor_opts, opts
      @input = input
      @output = output
      @tunnel_plugins = tunnel_plugins
      @statistics = statistics
      @debug = debug
      @processor_opts = processor_opts
      @tags = opts[:tags] || []
      @attributes = opts[:attributes] || {}
    end
  end
end