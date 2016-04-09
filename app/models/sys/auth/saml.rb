class Sys::Auth::Saml
  include Sys::Model::Auth
  include Sys::Addon::SamlSetting
  include Sys::Permission

  set_permission_name "sys_users", :edit
  default_scope ->{ where(model: 'sys/auth/saml') }

  def url
    "/.mypage/login/saml/#{filename}/init"
  end
end
