module Cms::Addon
  module CheckLinks
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :check_links_errors, type: Array
      field :check_links_errors_updated, type: DateTime

      scope :has_check_links_errors, ->{ where(:check_links_errors.exists => true) }
    end
  end
end
