class Sns::Login::SamlController < ApplicationController
  include Sns::BaseFilter
  include Sns::LoginFilter

  skip_before_action :verify_authenticity_token, raise: false, only: :consume
  skip_before_action :logged_in?
  before_action :set_item

  model Sys::Auth::Saml

  private

  def set_item
    @item ||= @model.find_by(filename: params[:id])
  end

  def settings
    @settings ||= OneLogin::RubySaml::Settings.new.tap do |settings|
      settings.assertion_consumer_service_url = sns_login_saml_url(id: @item.filename).sub(/\/init$/, "/consume")
      settings.issuer = sns_login_saml_url(id: @item.filename).sub(/\/init$/, "")
      settings.authn_context = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"

      settings.idp_entity_id = @item.entity_id
      settings.name_identifier_format = @item.name_id_format
      settings.idp_sso_target_url = @item.sso_url
      settings.idp_slo_target_url = @item.slo_url
      settings.idp_cert = SS::Crypt.decrypt(@item.x509_cert)
      settings.idp_cert_fingerprint = @item.fingerprint
      settings.force_authn = true if @item.force_authn?
    end
  end

  def authorize_failure
    Rails.logger.debug("authorize failure")
    raise "403"
  end

  public

  def init
    request = OneLogin::RubySaml::Authrequest.new
    state = SecureRandom.hex(24)
    session['ss.sso.state'] = { value: state, created: Time.zone.now.to_i, ref: params[:ref].try { |ref| ref.to_s } }
    redirect_to(request.create(settings, RelayState: state, ForceAuthn: "true"))
  end

  def consume
    state = params[:RelayState]
    session_state = session.delete('ss.sso.state')
    raise "404" if session_state.blank?
    raise "404" if session_state[:value] != state
    raise "404" if session_state[:created] + Sys::Auth::Base::READY_STATE_EXPIRES_IN < Time.zone.now.to_i

    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    response.settings = settings

    if !response.is_valid?
      render_login nil, nil, alert: response.status_message.presence
      return
    end

    user = SS::User.uid_or_email(response.nameid).and_enabled.and_unlocked.first
    if user.blank?
      Rails.logger.info("#{response.nameid}: user not found")
      render_login nil, nil
      return
    end

    params[:ref] = session_state[:ref]
    render_login user, nil, session: true, login_path: sns_login_path
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings), content_type: "application/samlmetadata+xml"
  end
end
