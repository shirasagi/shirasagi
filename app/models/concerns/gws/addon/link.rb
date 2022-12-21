module Gws::Addon::Link
  extend ActiveSupport::Concern
  extend SS::Addon

  concerning :Feature do
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      field :links, type: Array, default: []
      permit_params links: %i[name url target]

      validate :validate_links
    end

    def link_target_options
      %w(_self _blank).map do |v|
        [ I18n.t("ss.options.link_target.#{v}"), v ]
      end
    end

    private

    def validate_links
      items = links.to_a.select do |item|
        item.values.join.present?
      end
      self.links = items
    end
  end
end
