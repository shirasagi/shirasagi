class Cms::Column::Base
  include SS::Document
  include SS::Model::Column
  include Cms::Addon::Column::Layout
  include SS::Reference::Site

  store_in collection: 'cms_columns'

  class << self
    def default_attributes
      {
        name: self.model_name.human
      }
    end
  end

  def alignment_options
    %w(flow center).map { |v| [ I18n.t("cms.options.alignment.#{v}"), v ] }
  end

  def type_name
    return unless _type
    _type.delete_prefix("Cms::Column::").underscore
  end

  def db_form_type
    { type: 'input' }
  end

  def exact_match_to_value(value, operator: 'all')
    return if value.blank?

    case operator
    when 'any_of'
      { value: /#{::Regexp.escape(value)}/ }
    when 'start_with'
      { value: /\A#{::Regexp.escape(value)}/ }
    when 'end_with'
      { value: /#{::Regexp.escape(value)}\z/ }
    else
      { value: value }
    end
  end
end
