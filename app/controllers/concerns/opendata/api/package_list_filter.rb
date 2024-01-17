module Opendata::Api::PackageListFilter
  extend ActiveSupport::Concern

  def package_list
    @model = Opendata::Api::PackageListParam
    item = @model.new get_params
    render json: item.res
  end
end
