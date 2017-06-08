module SS::Addon::ApproveSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  included do
    field :forced_update, type: String
    permit_params :forced_update
  end
  def forced_update_options
    [
      [I18n.t("views.options.state.enabled"), "enabled"],
      [I18n.t("views.options.state.disabled"), "disabled"]
    ]
  end
end
