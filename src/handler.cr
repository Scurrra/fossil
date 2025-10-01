require "./router"
require "./params"
require "./methods"
require "./errors"

require "http/headers"

# Annotation for forced return content type.
#
# Note: almost everytime default content type is "application/json".
annotation ContentType end

macro method_added(endpoint_fun)
  {% for m in {GET, POST, PUT, HEAD, DELETE, PATCH, OPTIONS} %}     
    {% for m_ in endpoint_fun.annotations(m) %}
      %method = {{ m_.name.resolve.stringify }}
      %route = {{ m_[0] }}
      %tmp_name = "Endpoint::%method"
      
      class Endpoint%tmp_name < Fossil::Endpoint
        property return_content_type : String?

        def initialize
          {% if endpoint_fun.annotation(ContentType) %}
          @return_content_type = {{endpoint_fun.annotation(ContentType)[0]}}
          {% else %}
          @return_content_type = nil
          {% end %}
        end
    
        def call(context : HTTP::Server::Context, path_params : Hash(String, Fossil::Param::PathParamType))
          is_body_parsed = false
          form_data = {} of String => String
          file_data = {} of String => File
          if context.request.headers.has_key? "Content-Type"
            if context.request.headers.includes_word?("Content-Type", "multipart/form-data")
              HTTP::FormData.parse(context.request) do |part|
                if part.headers.includes_word?("Content-Disposition", "filename")
                  if filename = part.filename
                    file_data[part.name] = File.tempfile("::"+filename) do |file|
                      IO.copy(part.body, file)
                    end
                  end
                else
                  form_data[part.name] = part.body.gets_to_end
                end
              end
              is_body_parsed = true
            end
          end
      
          {% for arg in endpoint_fun.args %}
            {% if headerdep_ann_shadowed = arg.annotation(Fossil::Param::HeaderDep) %}
              
              %header = {{arg.annotation(Fossil::Param::HeaderDep)[0]}}
              unless context.request.headers.has_key?(%header)
                raise Fossil::Error::HeaderDependencyNotFoundError.new
              end
              begin
                {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.headers[%header]
              rescue
                raise Fossil::Error::HeaderDependencyNotSatisfiedError.new
              end
            
            {% elsif cookiedep_ann_shadowed = arg.annotation(Fossil::Param::CookieDep) %}
              
              %cookie = {{arg.annotation(Fossil::Param::CookieDep)[0]}}
              unless context.request.cookies.has_key?(%cookie)
                raise Fossil::Error::CookieDependencyNotFoundError.new
              end
              begin
                {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.cookies[%cookie].value
              rescue
                raise Fossil::Error::CookieDependencyNotSatisfiedError.new
              end

            {% elsif cookiedep_ann_shadowed = arg.annotation(Fossil::Param::GhostDep) %}
              
              begin
                {{arg.internal_name.id}} = {{arg.restriction}}.new
              rescue
                raise Fossil::Error::GhostDependencyInitializationError.new
              end

            {% elsif path_ann_shadowed = arg.annotation(Fossil::Param::Path) %}
              
              begin
              {% if path_ann_shadowed.named_args.has_key?(:name) %}
                {{arg.internal_name.id}} = path_params[{{arg.annotation(Fossil::Param::Path)[:name]}}]
              {% else %}
                {{arg.internal_name.id}} = path_params[{{arg.name.stringify}}]
              {% end %}
              rescue
                raise Fossil::Error::ParamParseError.new "Cannot parse path parameter #{{{arg.name.stringify}}}. Parameter's name in annotation has precedence."
              end
              
            {% elsif query_ann_shadowed = arg.annotation(Fossil::Param::Query) %}
              
              begin
              {% if query_ann_shadowed.named_args.has_key?(:name) && query_ann_shadowed.named_args.has_key?(:alias) %}
              
                {% if arg.restriction.stringify == "String" %}
                
                if context.request.query_params.has_key?({{arg.annotation(Fossil::Param::Query)[:name]}})
                  {{arg.internal_name.id}} = context.request.query_params[{{arg.annotation(Fossil::Param::Query)[:name]}}]
                elsif context.request.query_params.has_key?({{arg.annotation(Fossil::Param::Query)[:alias]}})
                  {{arg.internal_name.id}} = context.request.query_params[{{arg.annotation(Fossil::Param::Query)[:alias]}}]
                else
                  {{arg.internal_name.id}} = context.request.query_params[{{arg.name.stringify}}]
                end
              
                {% else %}

                if context.request.query_params.has_key?({{arg.annotation(Fossil::Param::Query)[:name]}})
                  {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.query_params[{{arg.annotation(Fossil::Param::Query)[:name]}}]
                elsif context.request.query_params.has_key?({{arg.annotation(Fossil::Param::Query)[:alias]}})
                  {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.query_params[{{arg.annotation(Fossil::Param::Query)[:alias]}}]
                else
                  {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.query_params[{{arg.name.stringify}}]
                end
              
                {% end %}
            
              {% elsif query_ann_shadowed.named_args.has_key?(:name) %}
              
                {% if arg.restriction.stringify == "String" %}
                
                if context.request.query_params.has_key?({{arg.annotation(Fossil::Param::Query)[:name]}})
                  {{arg.internal_name.id}} = context.request.query_params[{{arg.annotation(Fossil::Param::Query)[:name]}}]
                else
                  {{arg.internal_name.id}} = context.request.query_params[{{arg.name.stringify}}]
                end
              
                {% else %}

                if context.request.query_params.has_key?({{arg.annotation(Fossil::Param::Query)[:name]}})
                  {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.query_params[{{arg.annotation(Fossil::Param::Query)[:name]}}]
                else
                  {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.query_params[{{arg.name.stringify}}]
                end
              
                {% end %}
            
              {% else %}
              
                {% if arg.restriction.stringify == "String" %}
                
                {{arg.internal_name.id}} = context.request.query_params[{{arg.name.stringify}}]
              
                {% else %}

                {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.query_params[{{arg.name.stringify}}]

                {% end %}
            
              {% end %}
              rescue
                {% unless arg.default_value %}
                raise Fossil::Error::ParamParseError.new "Cannot parse query parameter #{{{arg.name.stringify}}}."
                {% else %}
                {{arg.internal_name.id}} = {{arg.default_value}}
                {% end %}
              end
            
            {% elsif form_ann_shadowed = arg.annotation(Fossil::Param::Form) %}
        
              if form_params = context.request.form_params?
                
                begin
                {% if form_ann_shadowed.named_args.has_key?(:name) && form_ann_shadowed.named_args.has_key?(:alias) %}
          
                  {% if arg.restriction.stringify == "String" %}
            
                  if context.request.form_params.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = context.request.form_params[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  elsif context.request.form_params.has_key?({{arg.annotation(Fossil::Param::Form)[:alias]}})
                    {{arg.internal_name.id}} = context.request.form_params[{{arg.annotation(Fossil::Param::Form)[:alias]}}]
                  else
                    {{arg.internal_name.id}} = context.request.form_params[{{arg.name.stringify}}]
                  end
            
                  {% else %}
            
                  if context.request.form_params.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.form_params[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  elsif context.request.form_params.has_key?({{arg.annotation(Fossil::Param::Form)[:alias]}})
                    {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.form_params[{{arg.annotation(Fossil::Param::Form)[:alias]}}]
                  else
                    {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.form_params[{{arg.name.stringify}}]
                  end
            
                  {% end %}
            
                {% elsif form_ann_shadowed.named_args.has_key?(:name) %}
          
                  {% if arg.restriction.stringify == "String" %}
            
                  if context.request.form_params.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = context.request.form_params[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  else
                    {{arg.internal_name.id}} = context.request.form_params[{{arg.name.stringify}}]
                  end
            
                  {% else %}
            
                  if context.request.form_params.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.form_params[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  else
                    {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.form_params[{{arg.name.stringify}}]
                  end
            
                  {% end %}
            
                {% else %}
          
                  {% if arg.restriction.stringify == "String" %}
            
                  {{arg.internal_name.id}} = context.request.form_params[{{arg.name.stringify}}]
            
                  {% else %}
            
                  {{arg.internal_name.id}} = {{arg.restriction}}.new context.request.form_params[{{arg.name.stringify}}]
            
                  {% end %}
            
                {% end %}
                rescue
                  {% unless arg.default_value %}
                  raise Fossil::Error::ParamParseError.new "Cannot parse form parameter #{{{arg.name.stringify}}}."
                  {% else %}
                  {{arg.internal_name.id}} = {{arg.default_value}}
                  {% end %}
                end

              else
                
                begin
                
                {% if form_ann_shadowed.named_args.has_key?(:name) && form_ann_shadowed.named_args.has_key?(:alias) %}
              
                {% if arg.restriction.stringify == "String" %}
              
                  if form_data.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = form_data[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  elsif form_data.has_key?({{arg.annotation(Fossil::Param::Form)[:alias]}})
                    {{arg.internal_name.id}} = form_data[{{arg.annotation(Fossil::Param::Form)[:alias]}}]
                  else
                    {{arg.internal_name.id}} = form_data[{{arg.name.stringify}}]
                  end
                
                {% else %}
                  
                  if form_data.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = {{arg.restriction}}.new form_data[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  elsif form_data.has_key?({{arg.annotation(Fossil::Param::Form)[:alias]}})
                    {{arg.internal_name.id}} = {{arg.restriction}}.new form_data[{{arg.annotation(Fossil::Param::Form)[:alias]}}]
                  else
                    {{arg.internal_name.id}} = {{arg.restriction}}.new form_data[{{arg.name.stringify}}]
                  end
                
                {% end %}
                
                {% elsif form_ann_shadowed.named_args.has_key?(:name) %}
                
                {% if arg.restriction.stringify == "String" %}
                
                  if form_data.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = form_data[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  else
                    {{arg.internal_name.id}} = form_data[{{arg.name.stringify}}]
                  end
                
                {% else %}
                  
                  if form_data.has_key?({{arg.annotation(Fossil::Param::Form)[:name]}})
                    {{arg.internal_name.id}} = {{arg.restriction}}.new form_data[{{arg.annotation(Fossil::Param::Form)[:name]}}]
                  else
                    {{arg.internal_name.id}} = {{arg.restriction}}.new form_data[{{arg.name.stringify}}]
                  end
                
                {% end %}

                {% else %}
                
                {% if arg.restriction.stringify == "String" %}
                  {{arg.internal_name.id}} = form_data[{{arg.name.stringify}}]
                {% else %}
                  {{arg.internal_name.id}} = {{arg.restriction}}.new form_data[{{arg.name.stringify}}]
                {% end %}

                {% end %}

                rescue
                  {% unless arg.default_value %}
                  raise Fossil::Error::ParamParseError.new "Cannot parse form parameter #{{{arg.name.stringify}}}."
                  {% else %}
                  {{arg.internal_name.id}} = {{arg.default_value}}
                  {% end %}
                end

              end

            {% elsif file_ann_shadowed = arg.annotation(Fossil::Param::File) %}

              begin
              {% if file_ann_shadowed.named_args.has_key?(:name) %}
                if file_data.has_key?({{arg.annotation(Fossil::Param::File)[:name]}})
                  {{arg.internal_name.id}} = file_data[{{arg.annotation(Fossil::Param::File)[:name]}}]
                else
                  {{arg.internal_name.id}} = file_data[{{arg.name.stringify}}]
                end
              {% else %}
                {{arg.internal_name.id}} = file_data[{{arg.name.stringify}}]
              {% end %}
              rescue
                raise Fossil::Error::ParamParseError.new "Cannot parse file parameter #{{{arg.name.stringify}}}. Parameter's name in annotation has precedence."
              end

            {% elsif body_ann_shadowed = arg.annotation(Fossil::Param::Body) %}
              
              if is_body_parsed
                raise Fossil::Error::ParamParseError.new "Cannot parse body parameter #{{{arg.name.stringify}}}. Body has been already parsed."
              end
              unless context.request.headers.has_key? "Content-Type"
                raise Fossil::Error::ParamParseError.new "Cannot parse body parameter #{{{arg.name.stringify}}}. Request does not have `Content-Type` header."
              end

              if body = context.request.body
                begin
                  case context.request.headers
                  when .includes_word?("Content-Type", "application/json")
                    {{arg.internal_name.id}} = {{arg.restriction}}.from_json body.gets_to_end
                  when .includes_word?("Content-Type", "text/plain")
                    {% if arg.restriction.stringify == "String" %}
                  
                    {{arg.internal_name.id}} = body.gets_to_end

                    {% else %}

                    raise Fossil::Error::ParamParseError.new "Cannot parse body parameter #{{{arg.name.stringify}}} of type #{{{arg.restriction.stringify}}}. Parsing from string is not suported, please parse string on your own."

                    {% end %}
                  else
                    {% if arg.restriction.stringify == "String" %}
                  
                    {{arg.internal_name.id}} = body.gets_to_end

                    {% else %}

                    raise Fossil::Error::ParamParseError.new "Cannot parse body parameter #{{{arg.name.stringify}}} of type #{{{arg.restriction.stringify}}}. No parser available."

                    {% end %}
                  end
                rescue exception : Fossil::Error::ParamParseError
                  raise exception
                rescue
                  raise Fossil::Error::ParamParseError.new "Cannot parse body parameter #{{{arg.name.stringify}}}."
                end
              else
                raise Fossil::Error::ParamParseError.new "Cannot parse body parameter #{{{arg.name.stringify}}}. No body provided."
              end

            {% else %}
              raise Fossil::Error::UnspecifiedParamError.new "Param #{{{arg.name.stringify}}} is not specified. Provide `Fossil::Param::` annotation to the parameter."
            {% end %}
          {% end %}

          {{endpoint_fun.body}}
        end
      end
  
      %route.endpoints[Fossil::MethodsEnum.parse(%method)] = Endpoint%tmp_name.new
    {% end %}
  {% end %}
end
