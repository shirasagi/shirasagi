module Opendata::Api::PackageListFilter
  extend ActiveSupport::Concern

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
      if check_count > 0
        error = {__type: "Validation Error"}
        messages.each do |key, value|
          error[key] = value
        end
      end

      return error
    end

    def integer?(s)
      i = Integer(s)
      check = true
    rescue
      check = false
    end

  public
    def package_list

      help = SS.config.opendata.api["package_list_help"]

      limit = params[:limit]
      offset = params[:offset]

      error = package_list_param_check?(limit, offset)
      if error.present?
        render json: {help: help, success: false, error: error} and return
      end

      datasets = Opendata::Dataset.site(@cur_site).public.order_by(name: 1)
      datasets = datasets.skip(offset) if limit.present? && offset.present?
      datasets = datasets.limit(limit) if limit.present?

      package_list = []
      datasets.each do |dataset|
        package_list << dataset[:name]
      end

      res = {help: help, success: true, result: package_list}
      render json: res
    end

end
