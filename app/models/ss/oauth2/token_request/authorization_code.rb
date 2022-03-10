class SS::OAuth2::TokenRequest::AuthorizationCode
  GRANT_TYPE = "authorization_code".freeze
  VALIDATION_HANDLERS = %i[validate_grant_type check_required_params authenticate_client parse_code parse_scope load_user].freeze

  def initialize(controller, unsafe_params)
    @controller = controller

    safe_params = unsafe_params.permit(:grant_type, :code, :redirect_uri)
    @grant_type = safe_params[:grant_type].to_s
    @code = safe_params[:code].to_s
    @redirect_uri = safe_params[:redirect_uri].to_s
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
    if @grant_type.blank? || @grant_type != GRANT_TYPE
      respond_error :bad_request, "unsupported_grant_type", "grant_type is not supported"
      return
    end
    true
  end

  def check_required_params
    if @code.blank?
      respond_error :bad_request, "invalid_request", "code is required"
      return
    end
    if @redirect_uri.blank?
      respond_error :bad_request, "invalid_request", "redirect_uri is required"
      return
    end
    true
  end

  def authenticate_client
    client_id, secret = SS::OAuth2.decode_application_name_and_secret(@controller.request.authorization)
    if client_id.blank? || secret.blank?
      respond_error :unauthorized, "invalid_client", "client authentication is required"
      return
    end

    application = SS::OAuth2::Application::Base.all.and_enabled.where(client_id: client_id).first
    if application.blank?
      respond_error :unauthorized, "invalid_client", "client is not registered"
      return
    end
    if application.client_secret != secret
      respond_error :bad_request, "unauthorized_client", "failed to authenticate"
      return
    end

    if !application.redirect_uris.include?(@redirect_uri)
      respond_error :bad_request, "access_denied", "redirect uri is mismatched"
      return
    end

    @application = application
    true
  end

  def parse_code
    jwt = JSON::JWT.decode_compact_serialized(@code, :skip_verification)
    jwt.verify! SS::Crypto.salt + SS::OAuth2::AUTHORIZATION_CODE_SALT

    expire_at = jwt[:exp]
    issue_at = jwt[:iat]
    if !expire_at.numeric? || !issue_at.numeric?
      respond_error :bad_request, "invalid_grant", "code is expired"
      return
    end

    expire_at = Time.zone.at(expire_at)
    if expire_at <= @now
      respond_error :bad_request, "invalid_grant", "code is expired"
      return
    end

    if jwt[:iss] != @application.name
      respond_error :unauthorized, "invalid_client", "client is not issued"
      return
    end

    @jwt = jwt
    true
  rescue
    respond_error :bad_request, "unauthorized_client", "code is malformed"
    false
  end

  def parse_scope
    scopes = @jwt[:scope].to_s.split
    unauthorized_scopes = scopes - @application.permissions
    if unauthorized_scopes.present?
      respond_error :bad_request, "invalid_scope", "requested scopes are not permitted"
      return
    end

    @scopes = scopes
    true
  end

  def load_user
    uid = @jwt["https://www.ss-proj.org/#uid"]
    if uid.blank?
      respond_error :bad_request, "invalid_grant", "code is unsatisfied"
      return
    end

    user = SS::User.where(id: uid).first
    if user.blank?
      respond_error :bad_request, "invalid_grant", "code is unsatisfied"
      return
    end

    if (user.uid.presence || user.email) != @jwt[:sub]
      respond_error :bad_request, "invalid_grant", "code is unsatisfied"
      return
    end

    @user = user
    true
  end
end
