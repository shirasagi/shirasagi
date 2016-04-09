class Sys::Auth::OpenIdConnect
  include Sys::Model::Auth
  include Sys::Addon::OpenIdConnectSetting
  include Sys::Permission

  set_permission_name "sys_users", :edit
  default_scope ->{ where(model: 'sys/auth/open_id_connect') }

  def url
    "/.mypage/login/oid/#{filename}/init"
  end
end
