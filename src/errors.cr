# Inner Fossil errors.
module Fossil::Error
  # Error raised when `Fossil::Router.new` is misused.
  class RouteParamError < Exception
    def initialize(message = "Wrong route parameter")
      super(message)
    end
  end

  # Error raised when path can not be traced from the router.
  class RouteTraceError < Exception
    def initialize(message = "Cannot trace the route")
      super(message)
    end
  end

  # Error raised when router parameters cannot be parsed.
  class ParamParseError < Exception
    def initialize(message = "Cannot parse param")
      super(message)
    end
  end
end
