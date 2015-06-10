module Opendata::Api::ResourceSearchFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def resource_search_check(query, order_by, offset, limit)

      offset_messages = []
      limit_messages = []

      query_message = "Missing value" if query.blank?

      check_num(offset, offset_messages)
      check_num(limit, limit_messages)

      messages = {}
      messages[:query] = query_message if query_message
      messages[:offset] = offset_messages if offset_messages.size > 0
      messages[:limit] = limit_messages if limit_messages.size > 0

      if messages.size > 0
        error = {__type: "Validation Error"}
        error = error.merge(messages)
      end

      return error
    end

  public
    def resource_search

      help = SS.config.opendata.api["resource_search_help"]

      query = params[:query]
      order_by = params[:order_by]
      offset = params[:offset]
      limit = params[:limit]

      error = resource_search_check(query, order_by, offset, limit)
      if error
        render json: {help: help, success: false, error: error} and return
      end

      result_list = []

      field, term =  URI.decode(query).split(":")

      field_list = %w(name description filename)
      if field_list.include?(field) == false
        error = {query: %(Field "#{field}" not recognised in resource_search.), __type: "Validation Error"}
        render json: {help: help, success: false, error: error} and return
      end

      if !term
        error = {query: "Must be <field>:<value> pair(s)", __type: "Validation Error"}
        render json: {help: help, success: false, error: error} and return
      end

      datasets = Opendata::Dataset.site(@cur_site).public.search_resources({keyword: term})
      datasets.each do |dataset|
        resources = dataset.resources
        resources.each do |resource|
          if field =~ /^name$/i && resource.name =~ /#{term}/i
            result_list << resource
          elsif field =~ /^description$/i && resource.text =~ /#{term}/i
            result_list << resource
          elsif field =~ /^filename$/i && resource.filename =~ /#{term}/i
            result_list << resource
          end
        end

        url_resources = dataset.url_resources
        url_resources.each do |url_resource|
          if field =~ /^name$/i && url_resource.name =~ /#{term}/i
            result_list << url_resource
          elsif field =~ /^description$/i && url_resource.text =~ /#{term}/i
            result_list << url_resource
          elsif field =~ /^filename$/i && url_resource.filename =~ /#{term}/i
            result_list << url_resource
          end
        end
      end

      if order_by
        if order_by =~ /^name$/i
          result_list.sort!{|a, b| a[:name] <=> b[:name] }
        elsif order_by =~ /^description$/i
          result_list.sort!{|a, b| a[:text] <=> b[:text] }
        elsif order_by =~ /^filename$/i
          result_list.sort!{|a, b| a[:filename] <=> b[:filename] }
        end
      end

      result_list = result_list[offset.to_i..-1] if offset
      result_list = result_list[0, limit.to_i] if limit

      if result_list.count > 0
        res = {help: help, success: true, result: convert_resources(result_list)}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res

    end

end
