# class Rdf::Extensions::Reference::Prop < Rdf::Extensions::QualifiedName
#   PROP_ID_KEY = "prop_id".freeze
#   PERMIT_KEYS = (Rdf::Extensions::QualifiedName::PERMIT_KEYS + [PROP_ID_KEY]).freeze
#
#   def initialize(document)
#     super
#   end
#
#   def prop_id
#     @document[PROP_ID_KEY]
#   end
#
#   def prop
#     ::Rdf::Prop.where(_id: prop_id).first
#   end
#
#   class << self
#     # Get the object as it was stored in the database, and instantiate
#     # this custom class from it.
#     def demongoize(object)
#       return nil if object.nil?
#       self.new(object)
#     end
#
#     # Takes any possible object and converts it to how it would be
#     # stored in the database.
#     def mongoize(object)
#       return nil if object.nil?
#       return nil if object.nil?
#       case object
#       when Hash
#         normalize_hash(object)
#       when String
#         normalize_string(object)
#       else
#         object
#       end
#     end
#
#     # Converts the object that was supplied to a criteria and converts it
#     # into a database friendly form.
#     def evolve(object)
#       object
#     end
#
#     private
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
#       prop = nil
#       if prefix.present? && name.present? && name != string
#         prop = Rdf::Prop.prefix_and_name(prefix, name).first
#       end
#
#       hash = {}
#       hash[Rdf::Extensions::QualifiedName::PREFIX_KEY] = prefix if prefix.present?
#       hash[Rdf::Extensions::QualifiedName::NAME_KEY] = name if name.present? && name != string
#       hash[Rdf::Extensions::QualifiedName::URI_KEY] = string
#       hash[PROP_ID_KEY] = prop.id if prop.present?
#       hash
#     end
#   end
# end
