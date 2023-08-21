class SS::OAuth2::AuthorizeRequest::Code
  RESPONSE_TYPE = 'code'.freeze

  def initialize(controller, user, unsafe_params)
    @controller = controller
    @user = user

    safe_params = unsafe_params.permit(:response_type, :client_id, :redirect_uri, :scope, :state)
    @response_type = safe_params[:response_type].to_s
    @client_id = safe_params[:client_id].to_s
    @redirect_uri = safe_params[:redirect_uri].to_s
    @scope = safe_params[:scope].to_s
    @state = safe_params[:state].to_s
    @now = Time.zone.now
  end

  def process
    if !@user
      redirect_to_login
      return
    end

    if @client_id.blank?
      respond_error :bad_request, "invalid_request", "client_id is required"
      return
    end
    if @redirect_uri.blank?
      respond_error :bad_request, "invalid_request", "redirect_uri is required"
      return
    end

    application = SS::OAuth2::Application::Base.all.and_enabled.where(client_id: @client_id).first
    if application.blank?
      respond_error :bad_request, "unauthorized_client", "client is not registered"
      return
    end

    if !application.redirect_uris.include?(@redirect_uri)
      respond_error :bad_request, "access_denied", "redirect uri is mismatched"
      return
    end

    if @scope.present?
      scopes = @scope.split
      unauthorized_scopes = scopes - application.permissions
      if unauthorized_scopes.present?
        redirect_error "access_denied", "requested scopes are not permitted"
        return
      end
    else
      scopes = application.permissions
    end

    jwt_code = JSON::JWT.new(
      # issuer
      iss: application.name,
      # subject
      sub: @user.uid.presence || @user.email,
      # scope
      scope: scopes.join(" "),
      # # audience
      # aud: @controller.request.fullpath,
      # expires at
      exp: (@now + 10.minutes).to_i,
      # issued at
      iat: @now.to_i,
      # 拡張属性
      "https://www.ss-proj.org/#uid" => @user.id
    )
    jwt_code = jwt_code.sign(SS::Crypto.salt + SS::OAuth2::AUTHORIZATION_CODE_SALT)

    response_json = { code: jwt_code.to_s }
    response_json[:state] = @state if @state.present?
    @controller.redirect_to @redirect_uri + "?" + response_json.to_query
  end

  private

  def respond_error(status, error, description)
    @controller.render json: { error: error, description: description }, status: status
  end

  def redirect_error(error, description)
    resp = { error: error, description: description }
    resp[:state] = @state if @state.present?

    @controller.redirect_to @redirect_uri + "#" + resp.to_query
  end

  def redirect_to_login
    @controller.respond_to do |format|
      format.html do
        if @controller.request.xhr?
          respond_error(:unauthorized, 'unauthorized', 'unauthorized')
          next
        end

        # login_path = login_path_by_cookie
        ref = @controller.request.fullpath
        if ref.present? && @controller.trusted_url?(ref)
          @controller.redirect_to sns_login_path(ref: ref)
        else
          @controller.redirect_to sns_login_path
        end
      end
      format.any { respond_error(:unauthorized, 'unauthorized', 'unauthorized') }
    end
  end
end
