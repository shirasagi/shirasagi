module Opendata::Api::TagShowFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  public
    def tag_show
      help = t("opendata.api.tag_show_help")
      id = params[:id]
      id = URI.decode(id) if id

      if !id
        error = {__type: "Validation Error", id: "Missing value"}
        render json: {help: help, success: false, error: error} and return
      end

      datasets = Opendata::Dataset.site(@cur_site).and_public.search({tag: id})

      if datasets.count > 0
        res = {help: help, success: true, result: convert_packages(datasets)}
      else
        res = {help: help, success: false}
        res[:error] = {message: "Not found", __type: "Not Found Error"}
      end

      render json: res
    end

end
