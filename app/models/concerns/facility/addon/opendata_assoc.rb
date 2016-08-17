module Facility::Addon::OpendataAssoc
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_ids :opendata_sites, class_name: "Cms::Site", metadata: { on_copy: :clear }
    field :csv_assoc, type: String, metadata: { on_copy: :clear }
    permit_params opendata_site_ids: []
    permit_params :csv_assoc
    validates :csv_assoc, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def csv_assoc_options
    %w(disabled enabled).map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end

  def csv_assoc_enabled?
    self.csv_assoc == 'enabled'
  end
end
