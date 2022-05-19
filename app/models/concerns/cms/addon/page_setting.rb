module Cms::Addon
  module PageSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :auto_description, type: String, default: "enabled"
      field :auto_keywords, type: String, default: "enabled"
      field :keywords, type: SS::Extensions::Words
      field :max_name_length, type: Integer, default: 80
      field :page_expiration_state, type: String, default: "disabled"
      field :page_expiration_before, type: String, default: "2.years"
      field :page_expiration_mail_subject, type: String
      field :page_expiration_mail_upper_text, type: String

      permit_params :auto_keywords, :auto_description
      permit_params :keywords
      permit_params :max_name_length
      permit_params :page_expiration_state, :page_expiration_before, :page_expiration_mail_subject
      permit_params :page_expiration_mail_upper_text

      validates :page_expiration_before, "ss/duration" => true
    end

    def auto_keywords_options
      [
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"],
      ]
    end

    def auto_description_options
      [
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"],
      ]
    end

    def page_expiration_state_options
      [
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"],
      ]
    end

    def auto_keywords_enabled?
      auto_keywords == "enabled"
    end

    def auto_description_enabled?
      auto_description == "enabled"
    end

    def page_expiration_enabled?
      page_expiration_state == "enabled"
    end

    def max_name_length_options
      [ 80, 0 ].map do |v|
        [ I18n.t("cms.options.max_name_length.#{v}"), v ]
      end
    end

    def page_expiration_before_options
      %w(90.days 180.days 1.year 2.years 3.years).map do |v|
        [ I18n.t("cms.options.page_expiration_before.#{v.sub(".", "_")}"), v ]
      end
    end

    def page_expiration_at(now = nil)
      now ||= Time.zone.now.beginning_of_day

      if page_expiration_before.present?
        expired_at = SS::Duration.parse(page_expiration_before)
      else
        expired_at = 2.years
      end
      now - expired_at
    end
  end
end
