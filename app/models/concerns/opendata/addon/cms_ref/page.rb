module Opendata::Addon::CmsRef::Page
  extend SS::Addon
  extend ActiveSupport::Concern
  include Opendata::CmsRef::Page

  included do
    field :assoc_method, type: String, default: 'auto'
    validates :assoc_method, inclusion: { in: %w(none auto) }
  end

  def assoc_method_options
    %w(none auto).map do |v|
      [ I18n.t("opendata.crawl_update_name.#{v}"), v ]
    end
  end
end
