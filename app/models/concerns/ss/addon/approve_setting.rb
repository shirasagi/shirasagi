module SS::Addon::ApproveSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  included do
    field :forced_update, type: String
    permit_params :forced_update
  end
  def forced_update_options
    [
      [I18n.t("views.options.state.disabled"), nil],
      [I18n.t("views.options.state.enabled"), true],
    ]
  end
end