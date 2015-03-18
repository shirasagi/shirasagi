module Opendata::AjaxFilter
  extend ActiveSupport::Concern

  included do
    layout "opendata/ajax"
  end
end
