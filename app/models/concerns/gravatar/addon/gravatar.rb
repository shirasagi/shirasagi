module Gravatar::Addon
  module Gravatar
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :gravatar_image_view_kind, type: String
      field :gravatar_email, type: String
      field :gravatar_screen_name, type: String
      permit_params :gravatar_image_view_kind, :gravatar_email, :gravatar_screen_name
      validates :gravatar_image_view_kind, inclusion: { in: %w(disable cms_user_email special_email), allow_blank: true }
      validates :gravatar_email, email: true
      validates :gravatar_email, presence: true, if: ->{ gravatar_image_view_kind == 'special_email' }
    end

    def email_for_gravatar
      Rails.logger.debug("#email_for_gravatar")
      view_kind = gravatar_image_view_kind.presence || SS.config.gravatar.view_kind
      Rails.logger.debug("view_kind=#{view_kind}")
      case view_kind
      when 'disable'
        nil
      when 'cms_user_email'
        Cms::User.find(user_id).email rescue nil
      when 'special_email'
        gravatar_email
      else
        raise StandardError, "Error! gravatar_image_view_kind is \"#{gravatar_image_view_kind}\"."
      end
    end

    def gravatar_image_view_kind_options
      [
        [I18n.t('mongoid.attributes.gravatar/addon/gravatar.gravatar_image_view_kind_disable'), 'disable'],
        [I18n.t('mongoid.attributes.gravatar/addon/gravatar.gravatar_image_view_kind_cms_user_email'), 'cms_user_email'],
        [I18n.t('mongoid.attributes.gravatar/addon/gravatar.gravatar_image_view_kind_special_email'), 'special_email'],
      ]
    end
  end
end
