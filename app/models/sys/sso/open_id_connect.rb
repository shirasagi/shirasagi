class Sys::Sso::OpenIdConnect
  include Sys::Model::SSO
  include Sys::Addon::OpenIdConnectSetting
  include Sys::Permission

  set_permission_name "sys_users", :edit
  default_scope ->{ where(route: 'sys/sso/open_id_connect') }

  def url
    "/.mypage/sso_login/oid/#{filename}/init"
  end
end
