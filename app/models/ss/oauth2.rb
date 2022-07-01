module SS::OAuth2
  AUTHORIZATION_CODE_SALT = "dfbe3db09bfd70aee0eabca53838a725e0a6f42b7bd9959f41ceab8ee4686db5" \
                            "f669e34ad1a446808ce9a78292b6197c757ba1e541dca6345b90345819fd20f8".freeze

  def self.decode_application_name_and_secret(authorization)
    return if authorization.blank?

    auth_scheme, auth_param = authorization.split(" ", 2)
    return if auth_scheme.blank? || !auth_scheme.casecmp("basic").zero? || auth_param.blank?

    decoded = Base64.decode64(auth_param) rescue nil
    return if decoded.blank?

    decoded.split(":", 2)
  end
end
