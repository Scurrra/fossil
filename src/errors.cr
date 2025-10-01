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

  # Error raised when router parameter's is unspecified 
  # (no param annotation provided).
  class UnspecifiedParamError < Exception
    def initialize(message = "Unspecified parameter.")
      super(message)
    end
  end

  # Error raised when cookie dependency is not found in cookies.
  class CookieDependencyNotFoundError < Exception
    def initialize(message = "Cookie Dependency Not Found")
      super(message)
    end
  end

  # Error raised when header dependency is not found in Headers.
  class HeaderDependencyNotFoundError < Exception
    def initialize(message = "Header Dependency Not Found")
      super(message)
    end
  end

  # Error raised when dependency can not be initialized from cookie value.
  class CookieDependencyNotSatisfiedError < Exception
    def initialize(message = "Cookie Dependency Not Satisfied")
      super(message)
    end
  end

  # Error raised when dependency can not be initialized from header value.
  class HeaderDependencyNotSatisfiedError < Exception
    def initialize(message = "Header Dependency Not Satisfied")
      super(message)
    end
  end

  # Error raised when ghost dependency's (dependency without parameters) 
  # constructor raised an error.
  class GhostDependencyInitializationError < Exception
    def initialize(message = "Ghost Dependency Was Not Initialized")
      super(message)
    end
  end
end
