module Samurai
  class Service
    class << self
      attr_accessor :routes, :configuration, :logger

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def resource(name, args)
        (@routes ||= {})[name] ||= {}
        
        exposed = args[:expose] || []
        @routes[name][:exposed] = (@routes[:exposed] || []) + exposed
        @routes[name][:controller] = args[:with] || "#{name.capitalize}Controller"
      end

      def start!(&block)
        `mkdir -p #{configuration.log_directory}`
        if configuration.log_clear_on_load
          `rm -f #{configuration.log_directory}/*`
        end

        @logger = Yell.new do |l|
          l.level = configuration.log_level
          l.adapter :file, "#{configuration.log_directory}/samurai.log"
        end

        logger.info "---"
        logger.info "Spawned listener processes for #{@routes.keys.inspect}"

        @listeners = @routes.keys.reduce({}) do |hash, k|
          reader, writer = IO.pipe

          hash[k] = {}
          hash[k][:pid] = fork do
            Listener.new resource: k, plan: @routes[k], config: @configuration, pipe: writer
          end
          
          # Wait for the listener to finish starting up
          writer.close
          raise 'Listener could not start' unless reader.read == 'READY'
          reader.close

          hash
        end

        begin
          block.call if block
        rescue Exception => e
          stop!
          raise e
        end
      end

      def stop!
        (@listeners ||= {}).each do |name, table|
          Process.kill 'TERM', table[:pid]
          Process.wait table[:pid]
        end
        logger.info "Stopped listener processes for #{@listeners.keys.inspect}"
      end
    end # << self

    class Configuration
      attr_accessor :message_queue_host, 
                    :message_queue_port, 
                    :log_level, 
                    :log_directory,
                    :log_clear_on_load

      def initialize
        @message_queue_host = '127.0.0.1'
        @message_queue_port = 5672
        @log_level          = :debug
        @log_directory      = 'log'
        @log_clear_on_load  = false
      end
    end
  end # Service
end # Samurai
