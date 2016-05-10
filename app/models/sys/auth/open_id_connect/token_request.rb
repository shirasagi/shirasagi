class Sys::Auth::OpenIdConnect::TokenRequest
  include ActiveModel::Model

  TIMEOUT = 30.seconds
  OPEN_TIMEOUT = 30.seconds

  attr_accessor :state
  attr_accessor :grant_type
  attr_accessor :code

  attr_accessor :cur_item
  attr_accessor :redirect_uri
  attr_accessor :session_state

  validates :state, presence: true
  validates :grant_type, presence: true
  validates :code, presence: true

  validates :cur_item, presence: true
  validates :session_state, presence: true

  validate :validate_state

  def initialize(*args)
    super
    self.grant_type ||= 'authorization_code'
  end

  def execute
    return nil if invalid?

    response = http_client.post do |req|
      req.options.timeout = TIMEOUT
      req.options.open_timeout = OPEN_TIMEOUT
      req.headers['Authorization'] = make_basic_auth
      req.params['grant_type'] = grant_type
      req.params['code'] = code
      req.params['redirect_uri'] = redirect_uri
    end

    unless json?(response.headers['Content-Type'])
      errors.add :base, :token_reponse_not_json
      return nil
    end

    body = JSON.parse(response.body.presence)
    body = ActionController::Parameters.new(body)
    body = body.permit(
      :access_token, :token_type, :refresh_token, :expires_in, :id_token,
      :error, :error_description, :error_uri)
    body[:cur_item] = cur_item

    ::Sys::Auth::OpenIdConnect::TokenResponse.new(body)
  end

  private
    def validate_state
      errors.add :state, :mismatch if state != session_state
    end

    def http_client
      @http_client ||= begin
        c = Faraday.new(url: cur_item.token_url) do |builder|
          builder.request  :url_encoded
          builder.response :logger, Rails.logger
          builder.adapter Faraday.default_adapter
        end
        c.headers[:user_agent] += " (SHIRASAGI/#{SS.version}; PID/#{Process.pid})"
        c
      end
    end

    def make_basic_auth
      user_pass = "#{cur_item.client_id}:#{SS::Crypt.decrypt(cur_item.client_secret)}"
      base64_user_pass = Base64.strict_encode64(user_pass)
      "Basic #{base64_user_pass}"
    end

    def json?(content_type)
      return false if content_type.blank?
      content_type.include?('application/json') || content_type.include?('text/json')
    end
end
