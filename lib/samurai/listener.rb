module Samurai
  class Listener
    attr_accessor :logger

    def initialize(args)
      @plan   = args[:plan]
      @logger = Yell.new(format: args[:config].log_format) do |l|
        l.level = args[:config].log_level

        if args[:config].log_to_file
          l.adapter :file, "#{args[:config].log_directory}/#{args[:resource]}_listener.log"
        end

        if args[:config].log_to_console
          l.adapter STDOUT, level: [:debug, :info, :warn]
          l.adapter STDERR, level: [:error, :fatal]
        end
      end

      logger.info "---"

      q_config   = {host: args[:config].message_queue_host, port: args[:config].message_queue_port}
      connection = Bunny.new(q_config)
      connection.start

      channel  = connection.create_channel
      exchange = channel.default_exchange

      q_name    = "samurai.service.#{args[:resource].to_s}"
      service_q = channel.queue q_name

      logger.info "Now listening on #{q_name}"

      # Let the service know we're ready to receive messages trhough a pipe
      args[:pipe].write('READY')
      args[:pipe].close
      begin
        service_q.subscribe(block: true) do |delivery_info, properties, payload|
          response = nil

          begin
            obj = JSON.parse(payload).with_indifferent_access
            raw_response = handle(obj)
            response = {type: 'response', status: raw_response[0], data: raw_response[1]}
          rescue Exception => e
            logger.error e
            response = {type: 'response', status: :exception, data: e}
          end

          exchange.publish(response.to_json, {
            routing_key:    properties.reply_to,
            correlation_id: properties.correlation_id
          })
        end
      rescue
        logger.warn "Listener shutting down"
        exit
      end
    end

    private
    def handle(obj)
      case obj['type']
      when 'request'
        handle_request obj
      when 'message'
        handle_message obj
      end
    end

    def handle_request(req)
      if @plan[:exposed].include? req['action'].to_sym
        controller = @plan[:controller]
        args = [req['action'].to_sym, req['data']]
        controller.is_a?(String) ? Kernel.const_get(controller).new(logger).try(*args) : controller.new(logger).try(*args)
      else
        [:not_found, "Action ##{req['action']} is not exposed by this service"]
      end
    end
  end
end