class Cms::Column::Base
  include SS::Document
  include SS::Model::Column
  include Cms::Addon::Column::Layout
  include SS::Reference::Site

  store_in collection: 'cms_columns'

  def alignment_options
    %w(flow center).map { |v| [ I18n.t("cms.options.alignment.#{v}"), v ] }
  end
end
