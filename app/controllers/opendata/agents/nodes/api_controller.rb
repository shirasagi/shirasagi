class Opendata::Agents::Nodes::ApiController < ApplicationController
  include Cms::NodeFilter::View

  before_action :accept_cors_request

  public
    def index
      render
    end

    def package_list

      help = SS.config.opendata.api["package_list_help"]

      limit = params[:limit]
      offset = params[:offset]

      check, messages = Opendata::Api.package_list_param_check?(limit, offset)
      if !check
        error = {}
        error[:__type] = "Validation Error"
        messages.each do |key, value|
          error[key] = value
        end

        res = {help: help, success: false, error: error}
        render json: res and return
      end

      @items = Opendata::Dataset.site(@cur_site).public.order_by(name: 1)

      if !limit.nil?
        @items = @items.skip(offset) if !offset.nil?
        @items = @items.limit(limit)
      end

      package_list = []
      @items.each do |item|
        package_list << item[:name]
      end

      res = {help: help, success: true, result: package_list}
      render json: res
    end

    def group_list

      help = SS.config.opendata.api["group_list_help"]

      sort = params[:sort] || "name"
      sort = sort.downcase
      groups = params[:groups]
      all_fields = params[:all_fields]

      check, messages = Opendata::Api.group_list_param_check?(sort)
      if !check
        error = {}
        error[:__type] = "Validation Error"
        messages.each do |key, value|
          error[key] = value
        end

        res = {help: help, success: false, error: error}
        render json: res and return
      end

      @items = Opendata::DatasetGroup.site(@cur_site).public
      @items = @items.order_by(name: 1) if sort == "name"

      group_list = []
      if all_fields.nil?
        @items.each do |item|
          group_list << item[:name]
        end
      else
        @items.each do |item|
          group = {id: item.id, state: item.state, name: item.name, order: item.order}
          group_list << group
        end
      end

      res = {help: help, success: true, result: group_list}
      render json: res
    end

    def tag_list
      help = SS.config.opendata.api["tag_list_help"]

      query = params[:query]
      #vocabulary_id = params[:vocabulary_id]
      #all_fields = params[:all_fields] || false

      @tags = Opendata::Dataset.site(@cur_site).public.get_tag_list(query)

      tag_list = []
      @tags.each do |tag|
        tag_list << tag["name"]
      end

      res = {help: help, success: true, result: tag_list}
      render json: res

    end

    def package_show

      help = SS.config.opendata.api["package_show_help"]

      id = params[:id]
      #use_default_schema = params[:use_default_schema]

      check, messages = Opendata::Api.package_show_param_check?(id)
      if !check
        error = {}
        error[:__type] = "Validation Error"
        messages.each do |key, value|
          error[key] = value
        end

        render json: {help: help, success: false, error: error} and return
      end

      @datasets = Opendata::Dataset.site(@cur_site).public
      @datasets = @datasets.any_of({"id" => id}, {"name" => id}).order_by(name: 1)

      if @datasets.count > 0
        res = {help: help, success: true, result: @datasets[0]}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

    def tag_show
      help = SS.config.opendata.api["tag_show_help"]
      id = params[:id]

      if id.blank?
        error = {__type: "Validation Error", id: "Missing value"}
        render json: {help: help, success: false, error: error} and return
      end

      @tags = Opendata::Dataset.site(@cur_site).public.get_tag(id)

      if @tags.count > 0
        res = {help: help, success: true, result: [@tags[0]["name"]]}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

    def group_show
      help = SS.config.opendata.api["group_show_help"]
      id = params[:id]
      include_datasets =params[:include_datasets]

      check, messages = Opendata::Api.group_show_param_check?(id)
      if !check
        error = {__type: "Validation Error"}
        messages.each do |key, value|
          error[key] = value
        end

        render json: {help: help, success: false, error: error} and return
      end

      @groups = Opendata::DatasetGroup.site(@cur_site).public
      @groups = @groups.any_of({"id" => id}, {"name" => id}).order_by(name: 1)

      if @groups.count > 0
        res = {help: help, success: true, result: @groups[0]}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

end
