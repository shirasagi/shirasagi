module Gws::Addon::Facility::InputSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :input_type, type: String, default: "text_field"
    field :select_options, type: SS::Extensions::Lines, default: ""
    field :required, type: String, default: "required"
    field :max_length, type: Integer
    field :place_holder, type: String
    field :additional_attr, type: String, default: ""
    permit_params :input_type, :required, :max_length, :place_holder, :additional_attr
    permit_params :select_options

    validates :input_type, presence: true, inclusion: {
      in: %w(text_field text_area email_field radio_button select check_box)
    }
    validates :max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
    validate :validate_select_options
  end

  def input_type_options
    %w(text_field text_area email_field radio_button select check_box).map do |v|
      [ I18n.t("inquiry.options.input_type.#{v}"), v ]
    end
  end

  def required_options
    [
      [I18n.t('inquiry.options.required.required'), 'required'],
      [I18n.t('inquiry.options.required.optional'), 'optional'],
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

  def html_options
    options = additional_attr_to_h
    options['maxlength'] = max_length if max_length.present?
    options['placeholder'] = place_holder if place_holder.present?
    options
  end

  def validate_value(record, attribute, hash)
    value = hash[id.to_s]
    if required? && value.blank?
      record.errors.add(:base, name + I18n.t('errors.messages.blank'))
    end

    if value.present?
      if %w(radio_button select).include?(input_type)
        unless select_options.include?(value)
          record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
        end
      end
      if %w(check_box).include?(input_type)
        value = [ value ].flatten.compact.select(&:present?)
        if (value - select_options).present?
          record.errors.add(:base, name + I18n.t('errors.messages.inclusion', value: value))
        end
      end
    end
  end

  private

  def validate_select_options
    if input_type =~ /(select|radio_button|check_box)/
      errors.add :select_options, :blank if select_options.blank?
    end
  end
end
