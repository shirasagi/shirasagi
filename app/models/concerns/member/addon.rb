module Member::Addon
  module Redirection
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :redirect_url, type: String, default: "/"
      permit_params :redirect_url
    end
  end

  module FormAuth
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :form_auth, type: String, default: "disabled"
      permit_params :form_auth
    end

    def form_auth_options
      [
        [I18n.t('member.options.form_auth.disabled'), "disabled"],
        [I18n.t('member.options.form_auth.enabled'), "enabled"]
      ]
    end
  end

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

  module TwitterOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:twitter)
    end
  end

  module FacebookOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:facebook)
    end
  end

  module YahooJpOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:yahoojp)
    end
  end

  module GoogleOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:google_oauth2)
    end
  end

  module GithubOauth
    extend SS::Addon
    extend ActiveSupport::Concern
    include Member::Addon::BaseOauth

    included do
      define_oauth_fields(:github)
    end
  end
end
