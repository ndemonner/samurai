module Samurai
  class Controller
    attr_accessor :logger, :params, :action

    def initialize(l = nil)
      @logger = l
    end

    def try(action, data = nil)
      @action = action
      @params = data
      if actionable?
        send(action)
      else
        [:not_found, "Exposed action ##{action.to_s} not defined on the controller"]
      end
    end

    private
    def actionable?
      respond_to?(action)
    end
  end
end