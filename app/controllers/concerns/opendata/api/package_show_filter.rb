module Opendata::Api::PackageShowFilter
  extend ActiveSupport::Concern

  def package_show
    @model = Opendata::Api::PackageShowParam
    item = @model.new get_params
    render json: item.res
  end
end
