class Sys::Auth::OpenIdConnect::JwtValidator < ActiveModel::Validator
  def validate(item)
    validate_jwt_header(item)
    validate_jwt_claims(item)
    validate_jwt_signature(item)
  end

  private
    def validate_jwt_header(item)
      return if item.jwt.nil?
      item.errors.add :base, :jwt_header_alg_blank if item.jwt.alg.blank?
    end

    def validate_jwt_claims(item)
      return if item.jwt.nil?

      item.errors.add :base, :jwt_claims_iss_blank if item.jwt["iss"].blank?
      item.errors.add :base, :jwt_claims_iss_invalid if item.jwt["iss"] != item.cur_item.issuer

      item.errors.add :base, :jwt_claims_sub_blank if item.jwt["sub"].blank?

      item.errors.add :base, :jwt_claims_aud_blank if item.jwt["aud"].blank?
      item.errors.add :base, :jwt_claims_aud_invalid if !item.jwt["aud"].include?(item.cur_item.client_id)

      item.errors.add :base, :jwt_claims_exp_blank if item.jwt["exp"].blank?

      item.errors.add :base, :jwt_claims_iat_blank if item.jwt["iat"].blank?

      item.errors.add :base, :jwt_claims_nonce_blank if item.jwt["nonce"].blank?
      item.errors.add :base, :jwt_claims_nonce_invalid if item.jwt["nonce"] != item.session_nonce
    end

    def validate_jwt_signature(item)
      return if item.jwt.nil?

      if item.jwt.send(:hmac?)
        validate_jwt_hmac_signature(item)
      elsif item.jwt.send(:rsa?) || item.jwt.send(:ecdsa?)
        validate_jwt_rsa_signature(item)
      else
        item.errors.add :base, :jwt_header_alg_invalid
      end
    rescue JSON::JWT::Exception
      item.errors.add :base, :jwt_signature_invalid
    end

    def validate_jwt_hmac_signature(item)
      item.jwt.verify!(SS::Crypt.decrypt(item.cur_item.client_secret))
    end

    def validate_jwt_rsa_signature(item)
      if item.jwt.kid.blank?
        item.errors.add :base, :jwt_header_kid_blank
        return
      end

      key = item.cur_item.jwks.where(kid: item.jwt.kid).first
      if key.blank?
        item.cur_item.update_jwks!
        key = item.cur_item.jwks.where(kid: item.jwt.kid).first
      end

      if key.blank?
        item.errors.add :base, :jwt_header_kid_not_found
        return
      end

      if key.alg != item.jwt.alg
        item.errors.add :base, :jwt_header_jwk_invalid
        return
      end

      item.jwt.verify!(key.to_jwk.to_key)
    end
end
