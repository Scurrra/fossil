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
      %method = {{ endpoint_fun.annotation(m).name.resolve.stringify }}
      %route = {{ endpoint_fun.annotation(m)[0] }}
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
            end
          end
      
          {% for arg in endpoint_fun.args %}
            {% if path_ann_shadowed = arg.annotation(Fossil::Param::Path) %}
              
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
                raise Fossil::Error::ParamParseError.new "Cannot parse query parameter #{{{arg.name.stringify}}}."
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
                  raise Fossil::Error::ParamParseError.new "Cannot parse form parameter #{{{arg.name.stringify}}}."
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
                  raise Fossil::Error::ParamParseError.new "Cannot parse form parameter #{{{arg.name.stringify}}}."
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

            {% end %}
          {% end %}

          {{endpoint_fun.body}}
        end
      end
  
      %route.endpoints[Fossil::MethodsEnum.parse(%method)] = Endpoint%tmp_name.new
    {% end %}
  {% end %}
end
