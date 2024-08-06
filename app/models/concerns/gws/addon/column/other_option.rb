module Gws::Addon::Column::OtherOption
  extend ActiveSupport::Concern
  extend SS::Addon

  OTHER_VALUE = "$other_value$".freeze

  included do
    field :other_state, type: String, default: 'disabled'
    field :other_required, type: String, default: 'optional'
    permit_params :other_state, :other_required
    permit_params branch_section_ids: []
  end

  def other_state_options
    %w(disabled enabled).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def other_state_enabled?
    other_state == 'enabled'
  end

  def other_required_options
    %w(optional required).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def other_required?
    other_required == 'required'
  end
end
