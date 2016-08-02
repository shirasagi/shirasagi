module Rdf::Builders::Context
  extend ActiveSupport::Concern
  include Rdf::Builders::Traversable

  attr_accessor :vocab

  def attributes
    @attributes ||= {}
  end

  def handlers
    @handlers ||= {}
  end

  def aliases
    @aliases ||= {}
  end

  def register_handler(key, handler)
    handlers[key] = handler
  end

  def alias_handler(new_name, original_name)
    raise if handlers[original_name].blank?
    aliases[new_name] = original_name
  end
end
