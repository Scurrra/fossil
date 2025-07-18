# Possible `HTTP::Request` methods.
#
# Annotations of the same names are used for identifying endpoint functions.
# This annotations are eximined on having unnamed parameter of type `Fossil::Router`.
#
# ```
# @[GET(root / "route_a" / "@param0:string")]
# def get_route_a(@[Fossil::Param::Path(name="param0")] somestr : String)
#   ...
# ```
enum Fossil::MethodsEnum
  GET
  POST
  PUT
  HEAD
  DELETE
  PATCH
  OPTIONS
end

# :nodoc:
annotation GET; end
# :nodoc:
annotation POST; end
# :nodoc:
annotation PUT; end
# :nodoc:
annotation HEAD; end
# :nodoc:
annotation DELETE; end
# :nodoc:
annotation PATCH; end
# :nodoc:
annotation OPTIONS; end
