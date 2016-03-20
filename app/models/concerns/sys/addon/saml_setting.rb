module Sys::Addon
  module SamlSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :metadata, type: String
      field :identifier, type: String
      attr_accessor :in_metadata, :rm_metadata
      permit_params :identifier
      permit_params :in_metadata, :rm_metadata
      before_validation :set_metadata, if: ->{ in_metadata }
      before_validation :reset_metadata, if: ->{ rm_metadata }
    end

    def default_identifier
      "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
    end

    private
      def set_metadata
        self.metadata = SS::Crypt.encrypt(in_metadata.read)
      end

      def reset_metadata
        self.metadata = nil
      end
  end
end
