require "./router"
require "./params"
require "./methods"

macro method_added(endpoint_fun)
  {% for m in {GET, POST, PUT, HEAD, DELETE, PATCH, OPTIONS} %}     
    {% for m_ in endpoint_fun.annotations(m) %}
      %method = {{ endpoint_fun.annotation(m).name.resolve.stringify }}
      %route = {{ endpoint_fun.annotation(m)[0] }}
      %tmp_name = "Endpoint::%method"
      
      class Endpoint%tmp_name < Fossil::Endpoint
        def initialize
        end
    
        def call(context : HTTP::Server::Context, path_params : Hash(String, Fossil::Param::PathParamType)) : {{ endpoint_fun.return_type }}
          form_data = {} of String => HTTP::FormData::Part
          HTTP::FormData.parse(context.request) do |part|
            form_data[part.name] = part
          end
      
          {% for arg in endpoint_fun.args %}
            {% if path_ann = arg.annotation(Fossil::Param::Path) %}
              {% if !path_ann.named_args.has_key?(:name) %}
                %path_ann[:name] = {{arg.name}}
              {% end %}
              {{arg.internal_name.id}} = path_params[%path_ann[:name]]
            {% elsif query_ann = arg.annotation(Fossil::Param::Query) %}
              {% if !query_ann.named_args.has_key?(:name) %}
                %query_ann[:name] = {{arg.name}}
              {% end %}
              {{arg.internal_name.id}} = if context.request.query_params.has_key?(%query_ann[:name])
                {{arg.restriction}}.new context.request.query_params[%query_ann[:name]]
              elsif query_ann.named_args.has_key?(:alias)
                {{arg.restriction}}.new context.request.query_params[%query_ann[:alias]]
              end
            {% elsif form_ann = arg.annotation(Fossil::Param::Form) %}
              {% if !form_ann.named_args.has_key?(:name) %}
                %form_ann[:name] = {{arg.name}}
              {% end %}
              {{arg.internal_name.id}} = if form_params = context.request.form_params?
                if form_params.has_key?(%form_ann[:name])
                  {{arg.restriction}}.new form_params[%form_ann[:name]]
                elsif form_params.has_key?(:alias)
                  {{arg.restriction}}.new form_params[%form_ann[:alias]]
                end
              elsif
                if form_data.has_key?(%form_ann[:name])
                  {{arg.restriction}}.new form_data[%form_ann[:name]]
                elsif form_params.has_key?(:alias)
                  {{arg.restriction}}.new form_data[%form_ann[:alias]]
                end
              end
            {% elsif file_ann = arg.annotation(Fossil::Param::File) %}
              {% if !file_ann.named_args.has_key?(:name) %}
                %file_ann[:name] = {{arg.name}}
              {% end %}
              {{arg.internal_name.id}} = if form_data.has_key?(%file_ann[:name])
                File.tempfile(form_data[%file_ann[:name]].filename || "upload") do |tmpfile|
                  IO.copy(form_data[%file_ann[:name]].body, file)
                end
              else
                nil
              end
            {% end %}
          {% end %}

          {{endpoint_fun.body}}
        end
      end
  
      %route.endpoints[Fossil::MethodsEnum.parse(%method)] = Endpoint%tmp_name.new
    {% end %}
  {% end %}
end
