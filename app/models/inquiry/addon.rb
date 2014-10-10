module Inquiry::Addon

  module Message
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :inquiry_html, type: String, default: ""
      field :inquiry_sent_html, type: String, default: ""

      permit_params :inquiry_html, :inquiry_sent_html
    end
  end

  module Captcha
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 210

    included do
      field :inquiry_captcha, type: String, default: "enabled"
      permit_params :inquiry_captcha

      public
        def inquiry_captcha_options
          [%w(使用する enabled), %w(使用しない disabled)]
        end

        def captcha_enabled?
          inquiry_captcha == "enabled"
        end
    end
  end

  module Notice
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 220

    included do
      field :notice_state, type: String, default: "disabled"
      field :notice_email, type: String
      field :from_name, type: String
      field :from_email, type: String
      permit_params :notice_state, :notice_email, :from_name, :from_email

      validate :validate_notify_mail

      public
        def notice_state_options
          [%w(使用する enabled), %w(使用しない disabled)]
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
  end

  module Reply
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 230

    included do
      field :reply_state, type: String, default: "disabled"
      field :reply_subject, type: String
      field :reply_upper_text, type: String, default: ""
      field :reply_lower_text, type: String, default: ""
      permit_params :reply_state, :reply_subject, :reply_upper_text, :reply_lower_text

      validate :validate_reply_mail

      public
        def reply_state_options
          [%w(使用する enabled), %w(使用しない disabled)]
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
  end

  module InputSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :input_type, type: String, default: "text_field"
      field :select_options, type: SS::Extensions::Array, default: ""
      field :required, type: String, default: "required"
      field :additional_attr, type: String, default: ""
      permit_params :input_type, :required, :additional_attr, :select_options

      validate :validate_select_options

      public
        def input_type_options
          [ %w(テキストボックス text_field), %w(テキストエリア text_area),
            %w(メールアドレス email_field), %w(ラジオボタン選択 radio_button),
            %w(プルダウン選択 select), %w(チェックボックス選択 check_box),
          ]
        end

        def required_options
          [ %w(必須 required), %w(任意 optional) ]
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
    end
  end
end
