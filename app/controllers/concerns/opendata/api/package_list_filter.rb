module Opendata::Api::PackageListFilter
  extend ActiveSupport::Concern
  include Opendata::Api

  private

  def package_list_check(limit, offset)
    limit_messages = []
    offset_messages = []

    check_num(limit, limit_messages)
    check_num(offset, offset_messages)

    messages = {}
    messages[:limit] = limit_messages if limit_messages.present?
    messages[:offset] = offset_messages if offset_messages.present?

    if messages.present?
      error = {__type: "Validation Error"}
      error = error.merge(messages)
    end

    return error
  end

  public

  def package_list
    help = t("opendata.api.package_list_help")

    limit = params[:limit]
    offset = params[:offset]

    error = package_list_check(limit, offset)
    if error
      render json: {help: help, success: false, error: error} and return
    end

    datasets = Opendata::Dataset.site(@cur_site).and_public
    datasets = datasets.skip(offset) if limit && offset
    datasets = datasets.limit(limit) if limit
    result = datasets.pluck(:uuid)

    res = { help: help, success: true, result: result }
    render json: res
  end
end
