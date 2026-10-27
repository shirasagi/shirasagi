module Cms::Addon::Tag
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :tags, type: SS::Extensions::Words
    permit_params :tags
    template_variable_handler(:tags, :template_variable_handler_tags)
    if respond_to? :liquidize
      liquidize do
        export :tags do
          if tags.blank?
            SS::EMPTY_ARRAY
          else
            tags.select(&:present?)
          end
        end
      end
    end
  end

  private

  def template_variable_handler_tags(_name, _issuer)
    return if tags.blank?
    tags.select(&:present?).map { ERB::Util.html_escape(_1.strip) }.join(" ")
  end
end
