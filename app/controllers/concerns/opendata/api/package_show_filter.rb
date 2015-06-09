module Opendata::Api::PackageShowFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def package_show_param_check?(id)

      id_message = []
      id_message << "Missing value" if id.blank?

      messages = {}
      messages[:name_or_id] = id_message if !id_message.empty?

      check_count = id_message.size
      if check_count > 0
        error = {__type: "Validation Error"}
        messages.each do |key, value|
          error[key] = value
        end
      end

      return error
    end

  public
    def package_show

      help = SS.config.opendata.api["package_show_help"]

      id = params[:id]
      id = URI.decode(id) if !id.nil?
      #use_default_schema = params[:use_default_schema]

      error = package_show_param_check?(id)
      if error.present?
        render json: {help: help, success: false, error: error} and return
      end

      datasets = Opendata::Dataset.site(@cur_site).public
      datasets = datasets.any_of({"id" => id}, {"name" => id}).order_by(name: 1)

      if datasets.count > 0
        res = {help: help, success: true, result: convert_package(datasets[0])}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

end
