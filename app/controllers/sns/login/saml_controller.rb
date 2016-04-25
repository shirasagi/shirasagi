class Sns::Login::SamlController < ApplicationController
  include Sns::BaseFilter

  skip_action_callback :verify_authenticity_token, only: :consume
  skip_action_callback :logged_in?
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
        settings.idp_cert = Base64.encode64(SS::Crypt.decrypt(@item.x509_cert))
        settings.idp_cert_fingerprint = @item.fingerprint
      end
    end

    def authorize_failure
      Rails.logger.debug("authorize failure")
      raise "403"
    end

  public
    def init
      request = OneLogin::RubySaml::Authrequest.new
      state = session['ss.sso.state'] = SecureRandom.hex(24)
      redirect_to(request.create(settings, RelayState: state))
    end

    def consume
      state = params[:RelayState]
      raise "404" if session.delete('ss.sso.state') != state

      response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
      response.settings = settings

      raise "403" unless response.is_valid?

      user = SS::User.uid_or_email(response.nameid).first
      user = nil if user && !user.enabled?

      if user
        set_user(user, { session: true, password: user.password })
        redirect_to SS.config.sns.logged_in_page
      else
        redirect_to SS.config.sns.logged_in_page, alert: t("sns.errors.invalid_login")
      end
    end

    def metadata
      meta = OneLogin::RubySaml::Metadata.new
      render :xml => meta.generate(settings), content_type: "application/samlmetadata+xml"
    end
end
