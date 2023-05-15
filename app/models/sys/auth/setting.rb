class Sys::Auth::Setting
  include SS::Document
  include Sys::Permission

  set_permission_name "sys_users", :edit

  field :form_auth, type: String, default: "enabled"
  permit_params :form_auth

  def form_auth_options
    [
      [I18n.t('ss.options.state.enabled'), "enabled"],
      [I18n.t('ss.options.state.disabled'), "disabled"]
    ]
  end

  def form_auth_enabled?
    form_auth != "disabled"
  end
end
