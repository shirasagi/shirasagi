module Opendata::Api::ResourceSearchFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  included do
    before_action :init_resource_search, only: [:resource_search]
  end

  private
    def resource_search_check(queries, order_by, offset, limit)
      offset_messages = []
      limit_messages = []

      query_message = "Missing value" if queries[0].blank?

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

      error
    end

    def convert_property_name(field)
      if field =~ /^name$/i
        property = "name"
      elsif field =~ /^description$/i
        property = "text"
      elsif field =~ /^filename$/i
        property = "filename"
      elsif field =~ /^format$/i
        property = "format"
      end

      property
    end

    def agree?(resource, queries)
      result = true

      queries.each do |query|
        field, term =  URI.decode(query).split(":")
        property = convert_property_name(field)
        if resource[property.to_sym] !~ /#{term}/i
          result = false
        end
      end

      result
    end

    def init_resource_search
      @help = t("opendata.api.resource_search_help")

      @queries = [params[:query]]
      @order_by = params[:order_by]
      @offset = params[:offset]
      @limit = params[:limit]

      error = resource_search_check(@queries, @order_by, @offset, @limit)
      if error
        render json: { help: @help, success: false, error: error }
        return
      end

      field, term =  URI.decode(@queries[0]).split(":")

      field_list = %w(name description filename format)
      unless field_list.include?(field)
        error = {query: %(Field "#{field}" not recognised in resource_search.), __type: "Validation Error"}
        render json: {help: @help, success: false, error: error}
        return
      end

      if !term
        error = {query: "Must be <field>:<value> pair(s)", __type: "Validation Error"}
        render json: {help: @help, success: false, error: error}
      end
    end

  public
    def resource_search
      @result_list = []

      datasets = Opendata::Dataset.site(@cur_site).public
      datasets.each do |dataset|
        resources = dataset.resources
        resources.each do |resource|
          @result_list << resource if agree?(resource, @queries)
        end

        url_resources = dataset.url_resources
        url_resources.each do |url_resource|
          @result_list << url_resource if agree?(url_resource, @queries)
        end
      end

      order = convert_property_name(@order_by)
      if @order_by && order
        @result_list.sort!{|a, b| a[order.to_sym] <=> b[order.to_sym] }
      end

      if @offset
        if @result_list.size < @offset.to_i
          @result_list = []
        else
          @result_list = @result_list[@offset.to_i..-1]
        end
      end

      @result_list = @result_list[0, @limit.to_i] if @limit

      if @result_list.count > 0
        res = {help: @help, success: true, result: convert_resources(@result_list)}
      else
        res = {help: @help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end
end
