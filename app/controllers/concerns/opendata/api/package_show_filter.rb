module Opendata::Api::PackageShowFilter
  extend ActiveSupport::Concern

  private

  def package_show_check(id)

    id_messages = []
    id_messages << "Missing value" if id.blank?

    messages = {}
    messages[:name_or_id] = id_messages if id_messages.present?

    if messages.present?
      error = {__type: "Validation Error"}
      error = error.merge(messages)
    end

    return error
  end

  public

  def package_show
    help = t("opendata.api.package_show_help")

    id = params[:id]

    error = package_show_check(id)
    if error
      render json: {help: help, success: false, error: error}
      return
    end

    dataset = Opendata::Dataset.site(@cur_site).and_public.
      where("$or" => [{ "uuid" => id }, { "filename" => id }]).first

    if dataset
      res = { success: true, result: convert_package(dataset), help: help }
    else
      res = { success: false, error: { message: "Not found", type: "Not Found Error" }, help: help }
    end

    render json: res
  end
end
