module Cms::Addon::Tag
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :tags, type: SS::Extensions::Words
    permit_params :tags
    template_variable_handler(:tags, :template_variable_handler_tags)
    if respond_to? :liquidize
      liquidize do
        export :tags
      end
    end
  end

  private

  def template_variable_handler_tags(name, issuer)
    self.tags.join(" ")
  end
end
