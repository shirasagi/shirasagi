module Opendata::Api::PackageShowFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private
    def package_show_check(id)

      id_messages = []
      id_messages << "Missing value" if id.blank?

      messages = {}
      messages[:name_or_id] = id_messages if id_messages.size > 0

      if messages.size > 0
        error = {__type: "Validation Error"}
        error = error.merge(messages)
      end

      return error
    end

  public
    def package_show
      help = t("opendata.api.package_show_help")

      id = params[:id]
      id = URI.decode(id) if id
      #use_default_schema = params[:use_default_schema]

      error = package_show_check(id)
      if error
        render json: {help: help, success: false, error: error} and return
      end

      datasets = Opendata::Dataset.site(@cur_site).and_public
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
