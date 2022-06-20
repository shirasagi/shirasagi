class SS::OAuth2::TokenRequest::ClientCredentials
  GRANT_TYPE = "client_credentials".freeze
  VALIDATION_HANDLERS = %i[validate_grant_type parse_authorization check_required_params authenticate_client parse_scope].freeze

  def initialize(controller, unsafe_params)
    @controller = controller

    safe_params = unsafe_params.permit(:grant_type, :client_id, :client_secret, :scope)
    @grant_type = safe_params[:grant_type].to_s
    @client_id = safe_params[:client_id].to_s
    @client_secret = safe_params[:client_secret].to_s
    @scope = safe_params[:scope].to_s
    @now = Time.zone.now
  end

  def process
    return unless VALIDATION_HANDLERS.all? { |handler| send(handler) }

    token = SS::OAuth2::Token.create_token!(@application, nil, @scopes)
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

  def parse_authorization
    return true if @controller.request.authorization.blank?
    @client_id, @client_secret = SS::OAuth2.decode_application_name_and_secret(@controller.request.authorization)
    true
  end

  def check_required_params
    if @client_id.blank?
      respond_error :bad_request, "invalid_request", "client_id is required"
      return
    end
    if @client_secret.blank?
      respond_error :bad_request, "invalid_request", "client_secret is required"
      return
    end
    true
  end

  def authenticate_client
    application = SS::OAuth2::Application::Base.all.and_enabled.where(client_id: @client_id).first
    if application.blank?
      respond_error :unauthorized, "invalid_client", "client is not registered"
      return
    end
    if application.client_secret != @client_secret
      respond_error :bad_request, "unauthorized_client", "failed to authenticate"
      return
    end

    @application = application
    true
  end

  def parse_scope
    if @scope.blank?
      @scopes = @application.permissions
      return true
    end

    scopes = @scope.to_s.split
    unauthorized_scopes = scopes - @application.permissions
    if unauthorized_scopes.present?
      respond_error :bad_request, "invalid_scope", "requested scopes are not permitted"
      return
    end

    @scopes = scopes
    true
  end
end
