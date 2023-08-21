class Sys::Auth::Environment
  include Sys::Model::Auth
  include Sys::Addon::EnvironmentSetting
  include Sys::Permission

  set_permission_name "sys_users", :edit
  default_scope ->{ where(model: 'sys/auth/environment') }

  def url(options = {})
    query = "?#{options.to_query}" if options.present?
    "/.mypage/login/env/#{filename}/login#{query}"
  end
end
