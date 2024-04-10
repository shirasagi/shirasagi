module Sys::Addon
  module SamlSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    # https://learn.microsoft.com/en-us/windows-server/identity/ad-fs/troubleshooting/ad-fs-tshoot-azure
    DEFAULT_AUTHN_CONTEXT = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport".freeze
    AUTHN_CONTEXT_MAP = {
      "password_protected_transport".freeze => "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport".freeze,
      "windows".freeze => "urn:federation:authentication:windows".freeze,
    }.freeze

    included do
      field :entity_id, type: String
      field :name_id_format, type: String, default: -> { default_identifier }
      field :sso_url, type: String
      field :slo_url, type: String
      field :x509_cert, type: String
      field :force_authn_state, type: String
      field :authn_context, type: String
      attr_accessor :in_metadata, :in_x509_cert

      permit_params :entity_id, :name_id_format, :sso_url, :slo_url, :x509_cert, :force_authn_state, :authn_context
      permit_params :in_metadata, :in_x509_cert
      before_validation :load_metadata, if: ->{ in_metadata }
      before_validation :set_x509_cert, if: ->{ in_x509_cert }
      validates :sso_url, presence: true
      validates :x509_cert, presence: true
      validates :force_authn_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
      validates :authn_context, inclusion: { in: AUTHN_CONTEXT_MAP.keys, allow_blank: true }
      validate :validate_x509_cert
    end

    def default_identifier
      "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
    end

    def name_id_format_options
      %w(
        urn:oasis:names:tc:SAML:2.0:nameid-format:persistent
        urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress
        urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified
      ).map do |v|
        [ v, v ]
      end
    end

    def force_authn_state_options
      %w(disabled enabled).map { |v| [ I18n.t("sys.options.force_authn_state.#{v}"), v ] }
    end

    def authn_context_options
      AUTHN_CONTEXT_MAP.keys.map { |v| [ I18n.t("sys.options.authn_context.#{v}"), v ] }
    end

    def fingerprint
      cert = OpenSSL::X509::Certificate.new(SS::Crypto.decrypt(x509_cert))
      Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(":")
    end

    def force_authn?
      force_authn_state == "enabled"
    end

    private

    def load_metadata
      idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
      settings = idp_metadata_parser.parse(in_metadata.read)
      self.entity_id = settings.idp_entity_id
      self.name_id_format = settings.name_identifier_format
      self.sso_url = settings.idp_sso_target_url || settings.idp_sso_service_url
      self.slo_url = settings.idp_slo_target_url || settings.idp_slo_service_url
      if settings.idp_cert
        cert = Base64.decode64(settings.idp_cert) rescue nil
      end
      if cert
        self.x509_cert = SS::Crypto.encrypt(cert)
      end
    end

    def set_x509_cert
      self.x509_cert = SS::Crypto.encrypt(in_x509_cert.read)
    end

    def validate_x509_cert
      fingerprint
    rescue
      errors.add :x509_cert, :invalid
    end
  end
end
