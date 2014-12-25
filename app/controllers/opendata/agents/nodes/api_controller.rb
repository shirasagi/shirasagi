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

      error = Opendata::Api.package_list_param_check?(limit, offset)
      if error.present?
        render json: {help: help, success: false, error: error} and return
      end

      @datasets = Opendata::Dataset.site(@cur_site).public.order_by(name: 1)
      @datasets = @datasets.skip(offset) if limit.present? && offset.present?
      @datasets = @datasets.limit(limit) if limit.present?

      package_list = []
      @datasets.each do |dataset|
        package_list << dataset[:name]
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

      error = Opendata::Api.group_list_param_check?(sort)
      if error.present?
        render json: {help: help, success: false, error: error} and return
      end

      @groups = Opendata::DatasetGroup.site(@cur_site).public
      @groups = @groups.order_by(name: 1) if sort == "name"

      group_list = []
      if all_fields.nil?
        @groups.each do |group|
          group_list << group[:name]
        end
      else
        @groups.each do |group|
          group_list << {id: group.id, state: group.state, name: group.name, order: group.order}
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
        tag_name = tag["name"]
        tag_list << tag["name"] if query.nil? || (query.present? && tag_name =~ /^.*#{query}.*$/i)
      end

      res = {help: help, success: true, result: tag_list}
      render json: res

    end

    def package_show

      help = SS.config.opendata.api["package_show_help"]

      id = params[:id]
      #use_default_schema = params[:use_default_schema]

      error = Opendata::Api.package_show_param_check?(id)
      if error.present?
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
      include_datasets = params[:include_datasets]

      error = Opendata::Api.group_show_param_check?(id)
      if error.present?
        render json: {help: help, success: false, error: error} and return
      end

      @groups = Opendata::DatasetGroup.site(@cur_site).public
      @groups = @groups.any_of({"id" => id}, {"name" => id}).order_by(name: 1)

      if @groups.count > 0
        group = @groups[0]
        @datasets = Opendata::Dataset.site(@cur_site).public.any_in dataset_group_ids: group[:id]
        group[:package_count] = @datasets.count
        group[:packages] = @datasets if include_datasets.nil? || include_datasets =~ /^true$/i
        res = {help: help, success: true, result: group}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

end
