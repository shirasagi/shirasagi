class Sys::Sso::Saml
  include Sys::Model::SSO
  include Sys::Addon::SamlSetting
  include Sys::Permission

  set_permission_name "sys_users", :edit
  default_scope ->{ where(route: 'sys/sso/saml') }

  def url
    "/.mypage/sso_login/saml/#{filename}/init"
  end
end
