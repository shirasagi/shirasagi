class Cms::Column::UrlField2 < Cms::Column::Base

  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''

  field :label_max_length, type: Integer
  field :label_place_holder, type: String

  field :link_max_length, type: Integer
  field :link_place_holder, type: String

  permit_params :html_tag, :html_additional_attr
  permit_params :label_max_length, :label_place_holder
  permit_params :link_max_length, :link_place_holder

  validates :html_tag, inclusion: { in: %w(a), allow_blank: true }
  validates :label_max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  validates :link_max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }

  def link_target_options
    %w(_blank).map do |v|
      [ I18n.t("ss.options.link_target.#{v}"), v ]
    end
  end

  def html_tag_options
    %w(a).map do |v|
      [ I18n.t("cms.options.html_tag.#{v}", default: v), v ]
    end
  end

  def form_options(type = nil)
    if type == :link_label
      options = {}
      options['maxlength'] = label_max_length if label_max_length.present?
      options['placeholder'] = label_place_holder.presence || I18n.t("cms.column_url_field.link_label_placeholder")
      options
    elsif type == :link_url
      options = {}
      options['maxlength'] = link_max_length if link_max_length.present?
      options['placeholder'] = link_place_holder.presence || I18n.t("cms.column_url_field.link_url_placeholder")
      options
    else
      super()
    end
  end

  def syntax_check_enabled?
    true
  end

  def link_check_enabled?
    true
  end

  def form_check_enabled?
    super || (label_max_length.present? && label_max_length > 0) || (link_max_length.present? && link_max_length > 0)
  end

  def db_form_type
    { type: 'textarea', rows: 2 }
  end

  def exact_match_to_value(value)
    { link_label: value }
  end
end
