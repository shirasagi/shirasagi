module Rdf::Builders::Context
  extend ActiveSupport::Concern
  include Rdf::Builders::Traversable

  attr_accessor :vocab

  def attributes
    @attributes ||= {}.with_indifferent_access
  end

  def handlers
    @handlers ||= {}.with_indifferent_access
  end

  def aliases
    @aliases ||= {}.with_indifferent_access
  end

  def register_handler(key, handler)
    handlers[key] = handler
  end

  def alias_handler(new_name, original_name)
    raise if handlers[original_name].blank?
    aliases[new_name] = original_name
  end
end
