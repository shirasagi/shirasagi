module Cms::Addon::File
  extend ActiveSupport::Concern
  extend SS::Addon
  include Cms::Reference::Files

  included do
    field :file_order, type: String
  end

  def file_order_options
    [ [I18n.t("cms.options.file.name"), "name"], [I18n.t("cms.options.file.upload"), "upload"] ]
  end
end
