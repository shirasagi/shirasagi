class SS::OAuth2::TokenRequest::JWTBearer
  GRANT_TYPE = "urn:ietf:params:oauth:grant-type:jwt-bearer".freeze
  MAX_ASSERTION_SIZE = 1_024 * 32
  VALIDATION_HANDLERS = %i[validate_grant_type parse_assertion parse_iss parse_scope validate_aud validate_exp parse_sub].freeze

  def initialize(controller, unsafe_params)
    safe_params = unsafe_params.permit(:grant_type, :assertion)
    @controller = controller
    @grant_type = safe_params[:grant_type].to_s
    @assertion = safe_params[:assertion].to_s
    @now = Time.zone.now
  end

  def process
    return unless VALIDATION_HANDLERS.all? { |handler| send(handler) }

    token = SS::OAuth2::Token.create_token!(@user, @scopes)
    expires_in = token.expiration_date.in_time_zone - @now
    response_json = {
      access_token: token.token, token_type: "Bearer", expires_in: expires_in.to_i
    }
    @controller.render json: response_json
  end

  private

  def respond_error(status, error, description)
    @controller.render json: { error: error, description: description }, status: status
  end

  def validate_grant_type
    if @grant_type != GRANT_TYPE
      respond_error :bad_request, "invalid_grant", "grant_type is not known"
      return
    end

    true
  end

  def parse_assertion
    if @assertion.blank?
      respond_error :bad_request, "invalid_assertion", "assertion is required"
      return
    end

    if @assertion.length > MAX_ASSERTION_SIZE
      respond_error :bad_request, "invalid_assertion", "assertion is too large"
      return
    end

    begin
      @jwt = JSON::JWT.decode_compact_serialized(@assertion, :skip_verification)
    rescue
      respond_error :bad_request, "invalid_assertion", "assertion is malformed"
      return
    end

    true
  end

  def parse_iss
    iss = @jwt[:iss]
    if iss.blank?
      respond_error :bad_request, "unauthorized_client", "assertion must contain 'iss'"
      return
    end

    application = SS::OAuth2::Application::Base.all.and_enabled.where(client_id: iss.to_s).first
    if application.blank?
      respond_error :bad_request, "unauthorized_client", "client is not registered"
      return
    end

    begin
      if application.is_a?(SS::OAuth2::Application::Service)
        @jwt.verify! application.public_key
      else
        @jwt.verify! application.client_secret
      end
    rescue
      respond_error :bad_request, "invalid_assertion", "JWT signature is invalid"
      return
    end

    @application = application
    true
  end

  def parse_scope
    scopes = @jwt[:scope]
    scopes = scopes.to_s.split
    unauthorized_scopes = scopes - @application.permissions
    if unauthorized_scopes.present?
      respond_error :bad_request, "invalid_scope", "requested scope is not permitted"
      return
    end

    @scopes = scopes
    true
  end

  def validate_aud
    aud = @jwt[:aud]
    if aud.blank?
      respond_error :bad_request, "invalid_aud", "assertion must contain 'aud'"
      return
    end

    aud = Addressable::URI.parse(aud.to_s) rescue nil
    if aud.blank? || !aud.absolute?
      respond_error :bad_request, "invalid_aud", "malformed aud"
      return
    end

    unless aud.path == @controller.request.path
      respond_error :bad_request, "invalid_aud", "malformed aud"
      return
    end

    true
  end

  def validate_exp
    exp = @jwt[:exp]
    return if exp.blank?

    iat = @jwt[:iat]
    if iat.blank? || !exp.numeric? || !iat.numeric?
      respond_error :bad_request, "invalid_exp", "malformed exp"
      return
    end

    exp = Time.zone.at(exp.to_i)
    if exp <= @now
      respond_error :bad_request, "invalid_exp", "assertion is expired"
      return
    end

    true
  end

  def parse_sub
    sub = @jwt[:sub]
    if sub.blank?
      respond_error :bad_request, "invalid_grant", "assertion must contain 'sub'"
      return
    end

    users = SS::User.all.and_enabled.uid_or_email(sub.to_s)
    if users.count != 1
      respond_error :bad_request, "invalid_grant", "invalid user-id"
      return
    end

    @user = users.first
    true
  end
end
