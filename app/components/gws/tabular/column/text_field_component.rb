#frozen_string_literal: true

class Gws::Tabular::Column::TextFieldComponent < ApplicationComponent
  include ActiveModel::Model
  include Gws::Tabular::Column::TextFieldComponent::Base

  SUB_COMPONENT_MAP = {
    "form_color" => FormColor,
    "form_color_i18n" => FormColor,
    "form_email" => FormEmail,
    "form_email_i18n" => FormEmail,
    "form_multi" => FormMulti,
    "form_multi_i18n" => FormMulti,
    "form_multi_html" => FormMultiHtml,
    "form_multi_html_i18n" => FormMultiHtml,
    "form_tel" => FormTel,
    "form_tel_i18n" => FormTel,
    "form_text" => FormText,
    "form_text_i18n" => FormTextI18n,
    "form_url" => FormUrl,
    "form_url_i18n" => FormUrl,
    "show_color" => ShowColor,
    "show_color_i18n" => ShowColor,
    "show_email" => ShowText,
    "show_email_i18n" => ShowTextI18n,
    "show_multi" => ShowMulti,
    "show_multi_html" => ShowMultiHtml,
    "show_tel" => ShowText,
    "show_tel_i18n" => ShowTextI18n,
    "show_text" => ShowText,
    "show_text_i18n" => ShowTextI18n,
    "show_url" => ShowUrl,
    "show_url_i18n" => ShowUrl,
  }.freeze

  def call
    types = []
    if type == :form
      types << "form"
    else
      types << "show"
    end

    case input_type
    when "multi"
      types << "multi"
    when "multi_html"
      types << "multi_html"
    else
      case validation_type
      when "email"
        types << "email"
      when "tel"
        types << "tel"
      when "url"
        types << "url"
      when "color"
        types << "color"
      else
        types << "text"
      end
    end

    if i18n_state == "enabled"
      types << "i18n"
    end

    path = types.join("_")
    component_class = SUB_COMPONENT_MAP[path]
    return "開発中" unless component_class

    component = component_class.new(
      cur_site: cur_site, cur_user: cur_user, value: value, type: type, column: column, form: form, locale: locale)
    render component
  end
end
