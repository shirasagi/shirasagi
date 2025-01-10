module Cms::Addon::File
  extend ActiveSupport::Concern
  extend SS::Addon
  include Cms::Reference::Files

  # # ページにのみ適用するため、ページモデルかどうかを判定
  # included do
  #   before_save :add_unused_class, if: :page_model?
  # end

  # private

  # # contains_urlsの値がvalue_contains_urlsと同じかどうかを判定
  # def in_used?(value_contains_urls)
  #   contains_urls == value_contains_urls
  # end

  # # ページモデルかどうかを判定
  # def page_model?
  #   is_a?(Cms::Model::Page)
  # end
end
