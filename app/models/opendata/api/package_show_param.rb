class Opendata::Api::PackageShowParam < Opendata::Api::ParamBase

  attr_accessor :id
  permit_params :id

  def help
    I18n.t("opendata.api.package_show_help")
  end

  private

  def res_valid
    item = Opendata::Dataset.site(site).and_public.
      where("$or" => [{ "uuid" => id }, { "filename" => id }]).first

    if item
      { success: true, result: convert_package(item), help: help }
    else
      { success: false, error: { message: "Not found", type: "Not Found Error" }, help: help }
    end
  end

  def validate_param
    return if id.present?
    self.errors.add :id, "Missing value"
  end
end
