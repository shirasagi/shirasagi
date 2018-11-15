class Cms::Column::Table < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  def header_type_options
    %w(top left top-left none).map do |v|
      [ I18n.t("cms.options.column_header_type.#{v}", default: v), v ]
    end
  end
end
