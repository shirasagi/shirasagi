module SS::Addon
  module MaintMode
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :maint_mode, type: String, default: "disabled"
      field :maint_remark, type: String
      embeds_ids :maint_excluded_users, class_name: "SS::User"

      permit_params :maint_mode, :maint_remark, maint_excluded_user_ids: []

      validates :maint_excluded_user_ids, presence: true, if: -> { maint_mode == "enabled" }
    end

    def maint_mode_options
      [
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"]
      ]
    end

    def maint_mode?
      maint_mode == "enabled"
    end

    def allowed_maint_user?(user_id)
      maint_excluded_user_ids.include?(user_id)
    end
  end
end
