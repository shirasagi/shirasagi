class Opendata::Agents::Nodes::ApiController < ApplicationController
  include Cms::NodeFilter::View

  before_action :accept_cors_request

  private
    def package_list_param_check?(limit, offset)

      limit_message = []
      offset_message = []

      if !limit.nil?
        if integer?(limit)
          if limit.to_i < 0
            limit_message << "Must be a natural number"
          end
        else
          limit_message << "Invalid integer"
        end
      end

      if !offset.nil?
        if integer?(offset)
          if offset.to_i < 0
            offset_message << "Must be a natural number"
          end
        else
          offset_message << "Invalid integer"
        end
      end

      messages = {}
      messages[:limit] = limit_message if !limit_message.empty?
      messages[:offset] = offset_message if !offset_message.empty?

      check_count = limit_message.size + offset_message.size
      if check_count == 0
        check = true
      else
        check = false
      end

      return check, messages
    end

    def package_show_param_check?(id)

      check = false
      id_message = []

      if id.nil? || id.empty?
        id_message << "Missing value"
      end

      messages = {}
      messages[:name_or_id] = id_message if !id_message.empty?

      check_count = id_message.size
      check = true if check_count == 0

      return check, messages
    end

    def group_list_param_check?(sort)

      sort_message = []
      sort_values = ["name", "packages"]

      sort_message << "Cannot sort by field `#{sort}`" if !sort_values.include?(sort)

      messages = {}
      messages[:sort] = sort_message if !sort_message.empty?

      check_count = sort_message.size
      if check_count == 0
        check = true
      else
        check = false
      end

      return check, messages
    end

    def group_show_param_check?(id)

      check = false
      id_message = []

      if id.blank?
        id_message << "Missing value"
      end

      messages = {}
      messages[:name_or_id] = id_message if !id_message.empty?

      check_count = id_message.size
      check = true if check_count == 0

      return check, messages
    end

    def integer?(s)
      i = Integer(s)
      check = true
    rescue
      check = false
    end

  public
    def index
      render
    end

    def package_list

      help = SS.config.opendata.api["package_list_help"]

      limit = params[:limit]
      offset = params[:offset]

      check, messages = package_list_param_check?(limit, offset)
      if !check
        error = {}
        error[:__type] = "Validation Error"
        messages.each do |key, value|
          error[key] = value
        end

        res = {}
        res[:help] = help
        res[:success] = false
        res[:error] = error

        render json: res and return
      end

      @items = Opendata::Dataset.site(@cur_site).public.order_by(name: 1)

      if !limit.nil?
        if !offset.nil?
          @items = @items.skip(offset)
        end
        @items = @items.limit(limit)
      end

      package_list = []
      @items.each do |item|
        package_list << item[:name]
      end

      res = {}
      res[:help] = help
      res[:success] = true
      res[:result] = package_list

      render json: res
    end

    def group_list

      help = SS.config.opendata.api["group_list_help"]

      sort = params[:sort] || "name"
      sort = sort.downcase
      groups = params[:groups]
      all_fields = params[:all_fields]

      check, messages = group_list_param_check?(sort)
      if !check
        error = {}
        error[:__type] = "Validation Error"
        messages.each do |key, value|
          error[key] = value
        end

        res = {}
        res[:help] = help
        res[:success] = false
        res[:error] = error

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
          group = {}
          group[:id] = item.id
          group[:state] = item.state
          group[:name] = item.name
          group[:order] = item.order
          group_list << group
        end
      end

      res = {}
      res[:help] = help
      res[:success] = true
      res[:result] = group_list

      render json: res
    end

    def tag_list
      help = SS.config.opendata.api["tag_list_help"]

      query = params[:query]
      #vocabulary_id = params[:vocabulary_id]
      #all_fields = params[:all_fields] || false

      @tags = Opendata::Dataset.site(@cur_site).public.get_tag_list(:tags)

      tag_list = []
      @tags.each do |tag|
        tag_list << tag["name"]
      end

      res = {}
      res[:help] = help
      res[:success] = true
      res[:result] = tag_list

      render json: res

    end

    def package_show

      help = SS.config.opendata.api["package_show_help"]

      id = params[:id]
      #use_default_schema = params[:use_default_schema]

      check, messages = package_show_param_check?(id)
      if !check
        error = {}
        error[:__type] = "Validation Error"
        messages.each do |key, value|
          error[key] = value
        end

        render json: {help: help, success: false, error: error} and return
      end

      @datasets = Opendata::Dataset.site(@cur_site).public.order_by(name: 1)
      @datasets = @datasets.any_of({"id" => id}, {"name" => id}).limit(1)

      if @datasets.count > 0
        res = {}
        res[:help] = help
        res[:success] = true
        res[:result] = @datasets[0]
      else
        res = {}
        res[:help] = help
        res[:success] = false
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

    def group_show
      help = SS.config.opendata.api["group_show_help"]
      id = params[:id]
      include_datasets =params[:include_datasets]

      check, messages = group_show_param_check?(id)
      if !check
        error = {__type: "Validation Error"}
        messages.each do |key, value|
          error[key] = value
        end

        render json: {help: help, success: false, error: error} and return
      end

      @groups = Opendata::DatasetGroup.site(@cur_site).public.order_by(name: 1)
      @groups = @groups.any_of({"id" => id}, {"name" => id})

      if @groups.count > 0
        res = {help: help, success: true, result: @groups[0]}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

end
