# class Rdf::Extensions::QualifiedName
#   include Rdf::Extensions::HashLike
#
#   PREFIX_KEY = "prefix".freeze
#   NAME_KEY = "name".freeze
#   URI_KEY = "uri".freeze
#   PERMIT_KEYS = [PREFIX_KEY, NAME_KEY, URI_KEY].freeze
#
#   attr_reader :document
#
#   def initialize(document)
#     @document = document
#   end
#
#   def prefix
#     @document[PREFIX_KEY]
#   end
#
#   def name
#     @document[NAME_KEY]
#   end
#
#   def uri
#     @document[URI_KEY]
#   end
#
#   def preferred_label
#     if prefix.present? && name.present?
#       "#{prefix}:#{name}"
#     else
#       uri
#     end
#   end
#
#   class << self
#     # # Get the object as it was stored in the database, and instantiate
#     # # this custom class from it.
#     # def demongoize(object)
#     #   return nil if object.nil?
#     #   Rdf::Extensions::QualifiedName.new(object)
#     # end
#
#     # Takes any possible object and converts it to how it would be
#     # stored in the database.
#     def mongoize(object)
#       return nil if object.nil?
#       case object
#       when self
#         mongoize_self(object)
#       when Hash
#         mongoize_hash(object)
#       when String
#         normalize_string(object)
#       else
#         object
#       end
#     end
#
#     # # Converts the object that was supplied to a criteria and converts it
#     # # into a database friendly form.
#     # def evolve(object)
#     #   object
#     # end
#     # # Converts the object that was supplied to a criteria and converts it
#     # # into a database friendly form.
#     # def evolve(object)
#     #   object
#     # end
#
#     def normalize_hash(hash)
#       return nil if hash.blank?
#       hash = hash.stringify_keys.reject { |_, v| v.blank? }.select { |k, _| PERMIT_KEYS.include?(k) }
#       return nil if hash.blank?
#       hash
#     end
#
#     def normalize_string(string)
#       return nil if string.blank?
#       prefix, name = Rdf::Vocab.qname(string)
#
#       hash = {}
#       hash[PREFIX_KEY] = prefix if prefix.present?
#       hash[NAME_KEY] = name if name.present? && name != string
#       hash[URI_KEY] = string
#       hash
#     end
#   end
# end
