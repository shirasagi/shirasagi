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

  def exact_match_to_value(value)
    { value: value }
  end
end
