module Inquiry::Addon
  module InputSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :input_type, type: String, default: "text_field"
      field :select_options, type: SS::Extensions::Lines, default: ""
      field :required, type: String, default: "required"
      field :additional_attr, type: String, default: ""
      field :input_confirm, type: String, default: ""
      permit_params :input_type, :required, :additional_attr, :select_options, :input_confirm

      validate :validate_select_options
      validate :validate_input_confirm_options
    end

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
        map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
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
end
