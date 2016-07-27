class Opendata::Agents::Nodes::ApiController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::Api::PackageListFilter
  include Opendata::Api::GroupListFilter
  include Opendata::Api::TagListFilter
  include Opendata::Api::PackageShowFilter
  include Opendata::Api::GroupShowFilter
  include Opendata::Api::TagShowFilter
  include Opendata::Api::PackageSearchFilter
  include Opendata::Api::ResourceSearchFilter

  before_action :accept_cors_request

end
