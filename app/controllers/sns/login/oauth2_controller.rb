class Sns::Login::OAuth2Controller < ApplicationController
  include SS::AuthFilter

  skip_before_action :verify_authenticity_token, raise: false

  def authorize
    response_type = params.permit(:response_type)[:response_type]
    case response_type
    when SS::OAuth2::AuthorizeRequest::Code::RESPONSE_TYPE
      request = SS::OAuth2::AuthorizeRequest::Code.new(self, get_user_by_session, params)
    when SS::OAuth2::AuthorizeRequest::Token::RESPONSE_TYPE
      request = SS::OAuth2::AuthorizeRequest::Token.new(self, get_user_by_session, params)
    else
      render json: { error: "unsupported_response_type" }, status: :bad_request
      return
    end

    request.process
  end

  def token
    grant_type = params.permit(:grant_type)[:grant_type]

    case grant_type
    when SS::OAuth2::TokenRequest::AuthorizationCode::GRANT_TYPE
      request = SS::OAuth2::TokenRequest::AuthorizationCode.new(self, params)
    when SS::OAuth2::TokenRequest::JWTBearer::GRANT_TYPE
      request = SS::OAuth2::TokenRequest::JWTBearer.new(self, params)
    else
      render json: { error: "unsupported_grant_type" }, status: :bad_request
      return
    end

    request.process
  end
end
