module Sys::Addon
  module SamlSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :entity_id, type: String
      field :name_id_format, type: String, default: -> { default_identifier }
      field :sso_url, type: String
      field :slo_url, type: String
      field :x509_cert, type: String
      attr_accessor :in_metadata, :in_x509_cert
      permit_params :entity_id, :name_id_format, :sso_url, :slo_url, :x509_cert
      permit_params :in_metadata, :in_x509_cert
      before_validation :load_metadata, if: ->{ in_metadata }
      before_validation :set_x509_cert, if: ->{ in_x509_cert }
      validates :sso_url, presence: true
      validates :x509_cert, presence: true
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

    def fingerprint
      cert = OpenSSL::X509::Certificate.new(SS::Crypt.decrypt(x509_cert))
      Digest::SHA1.hexdigest(cert.to_der).upcase.scan(/../).join(":")
    end

    private

      def load_metadata
        idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
        settings = idp_metadata_parser.parse(in_metadata.read)
        self.entity_id = settings.idp_entity_id
        self.name_id_format = settings.name_identifier_format
        self.sso_url = settings.idp_sso_target_url
        self.slo_url = settings.idp_slo_target_url
        self.x509_cert = SS::Crypt.encrypt(Base64.decode64(settings.idp_cert))
      end

      def set_x509_cert
        self.x509_cert = SS::Crypt.encrypt(in_x509_cert.read)
      end

      def validate_x509_cert
        fingerprint
      rescue
        errors.add :x509_cert, :invalid
      end
  end
end
