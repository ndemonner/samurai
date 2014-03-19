module Samurai
  class Controller
    attr_accessor :logger

    def initialize(l)
      @logger = l
    end

    def try(action, data = nil)
      unless !respond_to?(action)
        method(action).arity == 0 ? send(action) : send(action, data)
      else
        [:not_found, "Exposed action ##{action.to_s} not defined on the controller"]
      end
    end
  end
end