class Cms::Column::Table < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  def header_type_options
    %w(top left top-left none).map do |v|
      [ I18n.t("cms.options.column_header_type.#{v}", default: v), v ]
    end
  end

  def syntax_check_enabled?
    true
  end

  def link_check_enabled?
    true
  end

  def db_form_type
    { type: 'textarea', rows: 8 }
  end
end
