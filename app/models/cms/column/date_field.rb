class Cms::Column::DateField < Cms::Column::Base

  field :place_holder, type: String
  field :html_tag, type: String
  field :html_additional_attr, type: String, default: ''

  validates :html_tag, inclusion: { in: %w(span time), allow_blank: true }
  permit_params :place_holder, :html_tag, :html_additional_attr

  def html_tag_options
    %w(span time).map do |v|
      [ I18n.t("cms.options.html_tag.#{v}", default: v), v ]
    end
  end

  def form_options
    options = {}
    options['placeholder'] = place_holder if place_holder.present?
    options['class'] = %w(date js-date)
    options
  end

  def exact_match_to_value(value, operator: 'all')
    return if value.blank?

    case operator
    when 'any_of'
      { date: /#{::Regexp.escape(value)}/ }
    when 'start_with'
      { date: /\A#{::Regexp.escape(value)}/ }
    when 'end_with'
      { date: /#{::Regexp.escape(value)}\z/ }
    else
      { date: value }
    end
  end
end
