require "http/server"
require "uuid"

abstract class Fossil::Endpoint
  abstract def call(context : HTTP::Server::Context, path_params : Hash(String, Fossil::Param::PathParamType))
end

class Fossil::Route
  getter path : Nil | String
  getter parameter : Nil | String

  property children : Array(Route)
  property param_children : Hash(Fossil::Param::PathParamTypeEnum, Route)
  property endpoints : Hash(Fossil::Method, Fossil::Endpoint)

  def initialize(path = nil, parameter = nil)
    path.nil? && parameter.nil? && raise Fossil::Error::RouteParamError.new("Path fragment is not provided")
    !path.nil? && !parameter.nil? && raise Fossil::Error::RouteParamError.new("Path fragment can be either route string or path parameter")

    @path = path
    @parameter = parameter

    @children = [] of Route
    @param_children = {} of Fossil::Param::PathParamTypeEnum => Route
    @endpoints = {} of Fossil::Method => Fossil::Endpoint
  end

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

      new_child = Route.new parameter: parameter
      @param_children[parameter_t] = new_child
      return other == "" ? new_child : new_child / other
    else
      @children.each do |child|
        if child.path == path
          return other == "" ? child : child / other
        end
      end

      new_child = Route.new path: path
      @children << new_child
      return other == "" ? new_child : new_child / other
    end
  end

  def trace(path : String, path_params = {} of String => Fossil::Param::PathParamType) : Tuple(Route, Hash(String, Fossil::Param::PathParamType))
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
