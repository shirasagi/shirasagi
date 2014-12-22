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
      all_fields = params[:all_fields] || false

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
      if all_fields
        @items.each do |item|
          group = {}
          group[:id] = item.id
          group[:state] = item.state
          group[:name] = item.name
          group[:order] = item.order
          group_list << group
        end
      else
        @items.each do |item|
          group_list << item[:name]
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

end
