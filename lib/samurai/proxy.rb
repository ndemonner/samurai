module Samurai
  class Proxy
    include ActiveModel::Model

    class << self
      attr_accessor :configuration

      def configure
        options = [:message_queue]

        @configuration = Struct.new(*options).new
        yield @configuration
      end

      def provides(name)
        @resource = name

        options = if configured?(:message_queue)
          [:hostname, :port].reduce({}) do |hash, k| 
            hash[k] = configuration.message_queue[k] unless configuration.message_queue[k].nil?
            hash
          end
        else
          {}
        end

        start_connection(options) if @mq_exchange.nil?
      end

      def find(id)
        request = {
          action: :show,
          data:   { id: id }
        }
        response = make_request request
        if response && response[:status] == :ok
          new(response[:data])
        else
          nil
        end
      end

      def where(query)
        request = {
          action: :index,
          data:   { query: query }
        }
        response = make_request request
        if response && response[:status] == :ok
          response[:data].map { |instance_data| new(instance_data) }
        else
          []
        end
      end

      def all
        request = { action: :index }
        response = make_request request
        if response && response[:status] == :ok
          response[:data].map { |instance_data| new(instance_data) }
        else
          []
        end
      end

      private
      def start_connection(options)
        mq_connection = Bunny.new(options)
        mq_connection.start

        mq_channel    = mq_connection.create_channel
        @mq_exchange  = mq_channel.default_exchange
        @mq_reply_q   = mq_channel.queue '', exclusive: true
        @mq_service_q = "samurai.service.#{@resource.to_s}"
      end

      def configured?(key)
        !!@configuration && !!@configuration.send(key)
      end

      def make_request(request)
        request.merge! type: :request, resource: @resource

        correlation_id = "#{Time.now}---#{SecureRandom.hex(16)}"

        @mq_exchange.publish(request.to_json, {
          routing_key: @mq_service_q, 
          correlation_id: correlation_id, 
          reply_to: @mq_reply_q.name
        })

        response = nil

        @mq_reply_q.subscribe(block: true) do |delivery_info, properties, payload|
          if properties[:correlation_id] == correlation_id
            response = JSON.parse(payload).with_indifferent_access
            response[:status] = response[:status].to_sym
            delivery_info.consumer.cancel
          end
        end

        raise response[:data] if response[:status] == :exception

        response
      end
    end # << self

    def destroy
      request = {
        action: :destroy,
        data:   { id: self.id }
      }

      response = self.class.make_request request
      response && response[:status] == :ok
    end

    def save
      request = {
        action: persisted? ? :update : :create,
        data:   self.as_json
      }

      response = self.class.make_request request
      if response && response[:status] == :ok
        assign_attributes response[:data]
      else
        # Set errors and return nil
        nil
      end
    end

    def create(attrs)
      new(attrs).save
    end

    def update_attributes(changes)
      assign_attributes changes
      save
    end
    alias_method :update, :update_attributes

    def assign_attributes(changes)
      changes.each { |k, v| send("#{k}=", v) }
      self
    end
    alias_method :attributes=, :assign_attributes

    def persisted?
      !!self.id
    end

  end # Proxy
end # Samurai
