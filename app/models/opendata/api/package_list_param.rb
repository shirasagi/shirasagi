class Opendata::Api::PackageListParam < Opendata::Api::ParamBase

  attr_accessor :limit, :offset
  permit_params :limit, :offset

  def help
    I18n.t("opendata.api.package_list_help")
  end

  private

  def res_valid
    datasets = Opendata::Dataset.site(site).and_public
    datasets = datasets.skip(offset) if limit && offset
    datasets = datasets.limit(limit) if limit && limit > 0
    result = datasets.pluck(:uuid)

    { help: help, success: true, result: result }
  end

  def validate_param
    check_num(:limit)
    check_num(:offset)
  end
end
