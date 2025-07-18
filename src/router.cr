require "http/server"
require "uuid"

require "./methods"
require "./errors"
require "./params"

# Abstract Endpoint class. For each endpoint processing function
# a new Endpoint class is created, and in `call` method arguments
# for the function are extraxted and pased to the body of a function.
abstract class Fossil::Endpoint
  abstract def call(context : HTTP::Server::Context, path_params : Hash(String, Fossil::Param::PathParamType))
end

# Router class. A instance of a class is a node in a route tree.
class Fossil::Router
  # The first path fragment of a path that can be resolved to one of the endpoints down the tree from the current node.
  # If `@path.is_nil` the fragment is a path parameter.
  getter path : Nil | String
  # Name of a path parameter a path that can be resolved to one of the endpoints down the tree from the current node starts with.
  # While `@path` is a whole fragment between two slashes, `@parameter` is parsed from a fragment "@<parameter_name>:<parameter_type>",
  # where <parameter_type> is of type `Fossil::Param::PathParamTypeEnum` (string that can be parsed to this enum).
  getter parameter : Nil | String

  # `Router`s that may can go after `self` and do not start with a path parameter.
  property children : Array(Router)
  # `Router`s that may can go after `self` and do start with a path parameter.
  # Type of a parameter is a key in a `Hash`, so its capacity is equal to 3.
  property param_children : Hash(Fossil::Param::PathParamTypeEnum, Router)
  # `Endpoint`s at the route that is resolved to current `Router`.
  property endpoints : Hash(Fossil::MethodsEnum, Fossil::Endpoint)

  # Initializer for `Router`.
  def initialize(path = nil, parameter = nil)
    path.nil? && parameter.nil? && raise Fossil::Error::RouteParamError.new("Path fragment is not provided")
    !path.nil? && !parameter.nil? && raise Fossil::Error::RouteParamError.new("Path fragment can be either route string or path parameter")

    @path = path
    @parameter = parameter

    @children = [] of Router
    @param_children = {} of Fossil::Param::PathParamTypeEnum => Router
    @endpoints = {} of Fossil::MethodsEnum => Fossil::Endpoint
  end

  # New `Router`s are implicitly created with calling a slash operator.
  # ```
  # root = Fossil::Router.new ""
  # root / "route_a/its_child"
  # root / "route_b/@param1:int/info"
  # ```
  def /(other : String) : self
    slash_pos = other.index('/')
    unless slash_pos.nil?
      path = other[...slash_pos]
      other = other[(slash_pos + 1)..]
    else
      path = other
      other = ""
    end

    if path.starts_with?('@')
      parameter, t = path[1..].split(':', 2, remove_empty: true)
      parameter_t = Fossil::Param::PathParamTypeEnum.parse(t)

      @param_children.each do |child_t, child|
        if child_t == parameter_t
          if child.parameter == parameter
            return other == "" ? child : child / other
          else
            raise Fossil::Error::RouteParamError.new("In each node path parameters with the same type must have the same name. Parameter of the same type with name `#{child.parameter}` was provided in another route")
          end
        end
      end

      new_child = Router.new parameter: parameter
      @param_children[parameter_t] = new_child
      return other == "" ? new_child : new_child / other
    else
      @children.each do |child|
        if child.path == path
          return other == "" ? child : child / other
        end
      end

      new_child = Router.new path: path
      @children << new_child
      return other == "" ? new_child : new_child / other
    end
  end

  # Trace `path` down the tree from the current router and pass all found path parameters in `path_params`.
  def trace(path : String, path_params = {} of String => Fossil::Param::PathParamType) : Tuple(Router, Hash(String, Fossil::Param::PathParamType))
    slash_pos = path.index('/')
    unless slash_pos.nil?
      current = path[...slash_pos]
      path = path[(slash_pos + 1)..]
    else
      current = path
      path = ""
    end

    @children.each do |child|
      if child.path == current
        return path == "" ? {child, path_params} : child.trace(path, path_params)
      end
    end

    child = self
    is_parsed = false
    if @param_children.has_key?(Fossil::Param::PathParamTypeEnum::Int)
      child = @param_children[Fossil::Param::PathParamTypeEnum::Int]
      if param = child.parameter
        if parsed = current.to_i?
          is_parsed = true
          path_params[param] = parsed
        end
      end
    end
    if !is_parsed && @param_children.has_key?(Fossil::Param::PathParamTypeEnum::UUID)
      child = @param_children[Fossil::Param::PathParamTypeEnum::UUID]
      if param = child.parameter
        parsed_uuid : UUID? = UUID.new(current) rescue nil
        if parsed = parsed_uuid
          is_parsed = true
          path_params[param] = parsed
        end
      end
    end
    if !is_parsed && @param_children.has_key?(Fossil::Param::PathParamTypeEnum::String)
      child = @param_children[Fossil::Param::PathParamTypeEnum::String]
      if param = child.parameter
        is_parsed = true
        path_params[param] = current
      end
    end

    unless is_parsed
      raise Fossil::Error::RouteTraceError
    end
    return path == "" ? {child, path_params} : child.trace(path, path_params)
  end
end
