# Endpoint parameters.
module Fossil::Param
  # Union of possible types of path parameters.
  alias PathParamType = Int32 | UUID | String

  # Enum of possible types of path parameters.
  enum PathParamTypeEnum
    Int
    UUID
    String
  end

  # Annotation for path parameter argument in an endpoint function.
  # The annotation is examined for `:name` parameter,
  # if not provided the external name is used for searching for the value.
  annotation Path; end

  # Annotation for query parameter argument in an endpoint function.
  # The annotation is examined for `:name` parameter,
  # if not provided the external name is used for searching for the value.
  # If value not found, `:alias` parameter may be used for search.
  annotation Query; end

  # Annotation for form parameter argument in an endpoint function.
  # The annotation is examined for `:name` parameter,
  # if not provided the external name is used for searching for the value.
  # If value not found, `:alias` parameter may be used for search.
  annotation Form; end

  # Annotation for file parameter argument in an endpoint function.
  # The annotation is examined for `:name` parameter,
  # if not provided the external name is used for searching for the value.
  annotation File; end

  # Annotation for body parameter argument in an endpoint function.
  # The body can be either xml, json or plain.
  annotation Body; end

  # Annotation for a header dependency.
  #
  # NOTE: the argument annotated with this annotation must have a constructor 
  # that receives a string value as only argument, so it can not be of type String itself.
  annotation HeaderDep; end

  # Annotation for a Cookie dependency.
  #
  # NOTE: the argument annotated with this annotation must have a constructor 
  # that receives a string value as only argument, so it can not be of type String itself.
  annotation CookieDep; end

  # Annotation for a dependency with no construction parameters.
  #
  # NOTE: use it for singletons or classes with default behavior, like databse sessions.
  annotation GhostDep; end
end
