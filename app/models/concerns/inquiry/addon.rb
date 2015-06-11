module Inquiry::Addon
  module Message
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry_html, type: String, default: ""
      field :inquiry_sent_html, type: String, default: ""
      field :inquiry_results_html, type: String, default: ""

      permit_params :inquiry_html, :inquiry_sent_html, :inquiry_results_html
    end
  end

  module Captcha
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :inquiry_captcha, type: String, default: "enabled"
      permit_params :inquiry_captcha
    end

    public
      def inquiry_captcha_options
        [
          [I18n.t('inquiry.options.state.enabled'), 'enabled'],
          [I18n.t('inquiry.options.state.disabled'), 'disabled'],
        ]
      end

      def captcha_enabled?
        inquiry_captcha == "enabled"
      end
  end

  module Notice
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :notice_state, type: String, default: "disabled"
      field :notice_email, type: String
      field :from_name, type: String
      field :from_email, type: String
      permit_params :notice_state, :notice_email, :from_name, :from_email

      validate :validate_notify_mail
    end

    public
      def notice_state_options
        [
          [I18n.t('inquiry.options.state.enabled'), 'enabled'],
          [I18n.t('inquiry.options.state.disabled'), 'disabled'],
        ]
      end

      def notify_mail_enabled?
        notice_state == "enabled"
      end

    private
      def validate_notify_mail
        if notify_mail_enabled?
          [:notice_email, :from_email].each do |sym|
            errors.add sym, :blank if send(sym).blank?
          end
        end
      end
  end

  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reply_state, type: String, default: "disabled"
      field :reply_subject, type: String
      field :reply_upper_text, type: String, default: ""
      field :reply_lower_text, type: String, default: ""
      permit_params :reply_state, :reply_subject, :reply_upper_text, :reply_lower_text

      validate :validate_reply_mail
    end

    public
      def reply_state_options
        [
          [I18n.t('inquiry.options.state.enabled'), 'enabled'],
          [I18n.t('inquiry.options.state.disabled'), 'disabled'],
        ]
      end

      def reply_mail_enabled?
        reply_state == "enabled"
      end

    private
      def validate_reply_mail
        if reply_mail_enabled?
          [:reply_subject, :from_name, :from_email].each do |sym|
            errors.add sym, :blank if send(sym).blank?
          end
        end
      end
  end

  module InputSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :input_type, type: String, default: "text_field"
      field :select_options, type: SS::Extensions::Array, default: ""
      field :required, type: String, default: "required"
      field :additional_attr, type: String, default: ""
      field :input_confirm, type: String, default: ""
      permit_params :input_type, :required, :additional_attr, :select_options, :input_confirm

      validate :validate_select_options
      validate :validate_input_confirm_options
    end

    public
      def input_type_options
        [
          [I18n.t('inquiry.options.input_type.text_field'), 'text_field'],
          [I18n.t('inquiry.options.input_type.text_area'), 'text_area'],
          [I18n.t('inquiry.options.input_type.email_field'), 'email_field'],
          [I18n.t('inquiry.options.input_type.radio_button'), 'radio_button'],
          [I18n.t('inquiry.options.input_type.select'), 'select'],
          [I18n.t('inquiry.options.input_type.check_box'), 'check_box'],
        ]
      end

      def required_options
        [
          [I18n.t('inquiry.options.required.required'), 'required'],
          [I18n.t('inquiry.options.required.optional'), 'optional'],
        ]
      end

      def input_confirm_options
        [
          [I18n.t('inquiry.options.input_confirm.disabled'), 'disabled'],
          [I18n.t('inquiry.options.input_confirm.enabled'), 'enabled'],
        ]
      end

      def required?
        required == "required"
      end

      def additional_attr_to_h
        additional_attr.scan(/\S+?=".+?"/m).
          map { |s| s.split(/=/).size == 2 ? s.gsub(/"/, "").split(/=/) : nil }.
          compact.to_h
      end

    private
      def validate_select_options
        if input_type =~ /(select|radio_button|check_box)/
          errors.add :select_options, :blank if select_options.blank?
        end
      end

      def validate_input_confirm_options
        if input_type =~ /(select|radio_button|check_box|text_area)/ && input_confirm == 'enabled'
          errors.add :input_confirm, :invalid_input_type_for_input_confirm, input_type: label(:input_type)
        end
      end
  end

  module ReleasePlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :release_date, type: DateTime
      field :close_date, type: DateTime
      permit_params :release_date, :close_date

      validate :validate_release_date
    end

    module ClassMethods
      public
        def public(date = nil)
          date = Time.zone.now unless date
          super(date)
        end
    end

    public
      def public?
        if (release_date.present? && release_date > Time.zone.now) ||
           (close_date.present? && close_date < Time.zone.now)
          false
        else
          super
        end
      end

      def label(name)
        if name == :state
          state = public? ? "public" : "closed"
          I18n.t("views.options.state.#{state}")
        else
          super(name)
        end
      end

    private
      def validate_release_date
        self.released ||= release_date

        if close_date.present?
          if release_date.present? && release_date >= close_date
            errors.add :close_date, :greater_than, count: t(:release_date)
          end
        end
      end
  end

  module ReceptionPlan
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :reception_start_date, type: DateTime
      field :reception_close_date, type: DateTime
      permit_params :reception_start_date, :reception_close_date

      validate :validate_reception_date
    end

    public
      def reception_enabled?
        if (reception_start_date.present? && reception_start_date.to_date > Time.zone.now.to_date) ||
           (reception_close_date.present? && reception_close_date.to_date < Time.zone.now.to_date)
          false
        else
          true
        end
      end

    private
      def validate_reception_date
        if reception_start_date.present? || reception_close_date.present?
          if reception_start_date.blank?
            errors.add :reception_start_date, :empty
          elsif reception_close_date.blank?
            errors.add :reception_close_date, :empty
          elsif reception_start_date > reception_close_date
            errors.add :reception_close_date, :greater_than, count: t(:reception_start_date)
          end
        end
      end
  end
end
