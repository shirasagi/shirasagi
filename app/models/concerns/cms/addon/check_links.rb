module Cms::Addon
  module CheckLinks
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :check_links_errors, type: Array
      field :check_links_errors_updated, type: DateTime
    end
  end
end
