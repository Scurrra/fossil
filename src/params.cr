# Endpoint parameters.
module Fossil::Param
  # Union of possible types of path parameters.
  private alias PathParamType = Int32 | UUID | String

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
end
