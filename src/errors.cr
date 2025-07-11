module Fossil::Errors
  class RouteParamError < Exception
    def initialize(message = "Wrong route parameter")
      super(message)
    end
  end

  class RouteTraceError < Exception
    def initialize(message = "Cannot trace the route")
      super(message)
    end
  end
end
