module Opendata::Api::TagShowFilter
  extend ActiveSupport::Concern

  public
    def tag_show
      help = SS.config.opendata.api["tag_show_help"]
      id = params[:id]
      id = URI.decode(id) if !id.nil?

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

end
