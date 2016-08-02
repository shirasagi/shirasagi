module Rdf::Extensions::HashLike
  extend ActiveSupport::Concern
  extend Forwardable

  attr_reader :document

  def_delegators :@document, :[], :[]=, :keys, :values, :length, :size, :each, :to_h

  # Converts an object of this instance into a database friendly value.
  def mongoize
    @document
  end

  module ClassMethods
    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      return nil if object.nil?
      new(object)
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      return nil if object.nil?
      case object
      when self
        mongoize_self(object)
      when Hash
        mongoize_hash(object)
      else
        object
      end
    end

    # Converts the object that was supplied to a criteria and converts it
    # into a database friendly form.
    def evolve(object)
      object
    end

    def mongoize_self(object)
      return nil if object.blank?
      mongoize_hash(object.document)
    end

    def mongoize_hash(hash)
      return nil if hash.blank?
      hash = hash.stringify_keys.reject { |_, v| v.blank? }
      return nil if hash.blank?
      hash
    end
  end
end
