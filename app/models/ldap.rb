module Ldap
  INVALID_AD_INTERVAL = 0x7fff_ffff_ffff_ffff
  AD_INTERVAL_EPOCH = Time.zone.parse("1601-01-01T00:00:00Z").freeze

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

  module_function

  def normalize_dn(dn)
    return dn if dn.blank?

    array = []
    Net::LDAP::DN.new(dn).each_pair { |key, value| array << "#{key.downcase}=#{value}" }
    array.join(",")
  end

  # interval: 1601年1月1日(UTC)以降の100ナノ秒間隔の数
  # 1秒 = 10 ** 9 ナノ秒
  def ad_interval_to_time(interval)
    return if interval.blank? || !interval.numeric?

    interval = interval.to_i
    return if interval.zero? || interval == INVALID_AD_INTERVAL

    interval_in_secs = interval.to_f / (10 ** 7)
    AD_INTERVAL_EPOCH + interval_in_secs.seconds
  end
end
