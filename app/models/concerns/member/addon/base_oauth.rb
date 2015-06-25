module Member::Addon
  module BaseOauth
    extend ActiveSupport::Concern

    module ClassMethods
      def define_oauth_fields(provider)
        field "#{provider}_oauth", type: String, default: "disabled"
        field "#{provider}_client_id", type: String
        field "#{provider}_client_secret", type: String
        permit_params "#{provider}_oauth", "#{provider}_client_id", "#{provider}_client_secret"

        define_method("#{provider}_oauth_options") do
          [
            [I18n.t("member.options.#{provider}_oauth.disabled"), "disabled"],
            [I18n.t("member.options.#{provider}_oauth.enabled"), "enabled"]
          ]
        end
      end
    end
  end
end
