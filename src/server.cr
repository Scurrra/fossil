require "http/server"
require "http/status"
require "socket"
require "json"
require "uuid/json"

require "./router"
require "./handler"

# Wrapper around `HTTP::Server` that holds the root `Fossil::Router` for the app.
class Fossil::Server
  getter root : Fossil::Router
  getter http_server : HTTP::Server

  def initialize(*, root_path : String = "", handlers : Indexable(HTTP::Handler) = [] of HTTP::Handler)
    @root = Fossil::Router.new root_path

    @http_server = HTTP::Server.new handlers do |context|
      method = Fossil::MethodsEnum.parse context.request.method
      path = context.request.path[1..]
      if @root.path != ""
        if path.starts_with?(root_path)
          path = path[root_path.size + 1..]
        else
          context.response.respond_with_status HTTP::Status::BAD_GATEWAY
        end
      end
      router, path_params = @root.trace path
  
      unless router.endpoints.has_key?(method)
        context.response.respond_with_status(HTTP::Status::METHOD_NOT_ALLOWED, "No #{context.request.method} for this path")
      end

      endpoint = router.endpoints[method]
      begin
        response_data = endpoint.call(context, path_params)
      rescue exception
        context.response.respond_with_status(HTTP::Status::INTERNAL_SERVER_ERROR, exception.to_s)
      else
        if return_content_type = endpoint.return_content_type
          begin
            case return_content_type
            when "text/plain"
              context.response.print response_data
            when "application/xml", "text/xml", "text/html"
              #requires user to manually serialize before return
              #so typeof(response_data) is String
              context.response.print response_data
            when "application/json"
              context.response.print response_data.to_json
            else
              context.response.print response_data
            end
            
            # if print fails no content type is set manually
            context.response.content_type = return_content_type
          rescue exception
            
          end
        else
          if response_data.responds_to?(:to_json)
            context.response.content_type = "application/json"
            context.response.print response_data.to_json
          else
            context.response.content_type = "text/plain"
            context.response.print response_data
          end
        end
      end
    end
  end

  # Binds an inner `HTTP::Server` to `uri`.
  def bind(uri : String) : Socket::Address
    @http_server.bind(uri)
  end

  # :ditto:
  def bind(uri : URI) : Socket::Address
    @http_server.bind(uri)
  end

  # Creates a `TCPServer` listening on `127.0.0.1:port`, adds it as a socket
  # and starts the server. Blocks until the server is closed.
  def listen(port : Int32, reuse_port : Bool = false)
    @http_server.listen(port, reuse_port)
  end

  # Creates a `TCPServer` listening on `host:port`, adds it as a socket
  # and starts the server. Blocks until the server is closed.
  def listen(host : String, port : Int32, reuse_port : Bool = false)
    @http_server.listen(host, port, reuse_port)
  end

  # Starts the server. Blocks until the server is closed.
  def listen : Nil
    @http_server.listen
  end

  # Gracefully terminates the server. It will process currently accepted
  # requests, but it won't accept new connections.
  def close : Nil
    @http_server.close
  end
end
