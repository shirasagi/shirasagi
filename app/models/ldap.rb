module Ldap
  mattr_accessor :url, :openssl_verify_mode, :sync_password, :auth_method, :admin_user, :admin_password

  self.url = begin
    url = SS.config.ldap.url
    if url.blank? && SS.config.ldap.host.present?
      # 過去との互換性: かつてSS.config.ldap.hostだった。LDAPSへ対応する必要があった際にSS.config.ldap.urlに変わった
      url = "ldap://#{SS.config.ldap.host}/"
    end
    url.freeze
  end

  self.openssl_verify_mode = SS.config.ldap.openssl_verify_mode.try(:freeze)
  self.sync_password = SS.config.ldap.sync_password.try(:freeze)
  self.auth_method = SS.config.ldap.auth_method.try(:to_sym)
  self.admin_user = SS.config.ldap.admin_user.try(:freeze)
  self.admin_password = SS.config.ldap.admin_password.try(:freeze)
end
