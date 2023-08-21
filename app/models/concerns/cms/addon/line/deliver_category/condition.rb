module Cms::Addon
  module Line::DeliverCategory::Condition
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :condition_state, type: String, default: "enabled"
      field :conditions, type: SS::Extensions::Lines
      permit_params :condition_state, :conditions
    end

    def condition_state_options
      [
        [I18n.t('ss.options.state.enabled'), 'enabled'],
        [I18n.t('ss.options.state.disabled'), 'disabled'],
      ]
    end

    def condition_enabled?
      condition_state == "enabled"
    end

    def required_selections
      @_required_selections = conditions.map do |filename|
        Cms::Line::DeliverCategory::Selection.site(site).
          where(filename: filename).first
      end.compact
    end

    def effective_with?(other_ids)
      return true if required_selections.blank?
      (required_selections.map(&:id) & other_ids).present?
    end

    def data_required_html
      return "" if conditions.blank?
      return "" if required_selections.blank?
      "data-required=\"#{required_selections.map(&:id).join(",")}\""
    end
  end
end
