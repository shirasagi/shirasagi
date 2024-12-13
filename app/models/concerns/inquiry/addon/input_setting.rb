module Inquiry::Addon
  module InputSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :input_type, type: String, default: "text_field"
      field :select_options, type: SS::Extensions::Lines, default: ""
      field :required, type: String, default: "required"
      field :required_in_select_form, type: Array
      field :additional_attr, type: String, default: ""
      field :input_confirm, type: String, default: ""
      field :question, type: String, default: 'disabled'
      field :max_upload_file_size, type: Integer, default: 0
      field :transfers, type: Array
      permit_params :input_type, :required, :additional_attr
      permit_params :select_options, :input_confirm, :question, :max_upload_file_size
      permit_params required_in_select_form: []
      permit_params transfers: [:keyword, :email]

      validates :input_type, presence: true, inclusion: {
        in: %w(text_field text_area email_field radio_button select check_box upload_file form_select)
      }
      validates :question, presence: true, inclusion: {
        in: %w(enabled disabled)
      }
      validate :validate_select_options
      validate :validate_input_confirm_options
      # validate :validate_max_upload_file_size_options
      validate :validate_transfers
      validate :validate_form_select
      validate :validate_question
    end

    def input_type_options
      %w(text_field text_area email_field radio_button select check_box upload_file form_select).map do |v|
        [ I18n.t("inquiry.options.input_type.#{v}"), v ]
      end
    end

    def required_options
      [
        [I18n.t('inquiry.options.required.required'), 'required'],
        [I18n.t('inquiry.options.required.optional'), 'optional'],
      ]
    end
    alias required_in_reply_options required_options

    def input_confirm_options
      [
        [I18n.t('inquiry.options.input_confirm.disabled'), 'disabled'],
        [I18n.t('inquiry.options.input_confirm.enabled'), 'enabled'],
      ]
    end

    def question_options
      %w(disabled enabled).map do |v|
        [ I18n.t("ss.options.state.#{v}"), v ]
      end
    end

    # def max_upload_file_size_options
    #   [ 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 ]
    # end

    def required?(in_reply)
      return true if in_reply && required_in_select_form && required_in_select_form.include?(in_reply)
      required == "required"
    end

    def additional_attr_to_h
      additional_attr.scan(/\S+?=".+?"/m).
        map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
        compact.to_h
    end

    private

    def validate_select_options
      if /(select|radio_button|check_box|form_select)/.match?(input_type)
        errors.add :select_options, :blank if select_options.blank?
      end
    end

    def validate_input_confirm_options
      if /(select|radio_button|check_box|text_area|upload_file)/.match?(input_type) && input_confirm == 'enabled'
        errors.add :input_confirm, :invalid_input_type_for_input_confirm, input_type: label(:input_type)
      end
    end

    # def validate_max_upload_file_size_options
    #   if input_type =~ /(max_upload_file_size)/
    #     errors.add :select_options, :blank if select_options.blank?
    #   end
    # end

    def validate_transfers
      return if transfers.blank?
      transfers.each do |transfer|
        return errors.add :base, :blank_keyword if transfer[:keyword].blank? && transfer[:email].present?
        return errors.add :base, :blank_email if transfer[:keyword].present? && transfer[:email].blank?
      end
    end

    def validate_form_select
      return if input_type != 'form_select'
      return unless node

      column = node.columns.where(input_type: 'form_select').first
      if column.present? && column != self
        errors.add :input_type, :exist_form_select, input_type: label(:input_type)
      end
    end

    def validate_question
      return if input_type != "upload_file"
      self.question = "disabled"
    end
  end
end
