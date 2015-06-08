module Opendata::Api::ResourceSearchFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def resource_search_param_check?(query, order_by, offset, limit)

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

      error = resource_search_param_check?(query, order_by, offset, limit)
      if error
        render json: {help: help, success: false, error: error} and return
      end

      result_list = []

      field, term =  URI.decode(query).split(":")
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
          elsif field =~ /^text$/i && resource.text =~ /#{term}/i
            result_list << resource
          elsif field =~ /^filename$/i && resource.filename =~ /#{term}/i
            result_list << resource
          end
        end

        url_resources = dataset.url_resources
        url_resources.each do |resource|
          if field =~ /^name$/i && resource.name =~ /#{term}/i
            result_list << resource
          elsif field =~ /^text$/i && resource.text =~ /#{term}/i
            result_list << resource
          elsif field =~ /^filename$/i && resource.filename =~ /#{term}/i
            result_list << resource
          end
        end
      end

      if order_by
        if order_by =~ /^name$/i
          resource_list.sort!{|a, b| a[:name] <=> b[:name] }
        end
      end

      result_list = result_list[offset.to_i..-1] if offset
      result_list = result_list[0, limit.to_i] if limit

      if result_list.count > 0
        res = {help: help, success: true, result: result_list}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res

    end

end
