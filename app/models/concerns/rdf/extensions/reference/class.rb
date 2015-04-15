# class Rdf::Extensions::Reference::Class < Rdf::Extensions::QualifiedName
#   CLASS_ID_KEY = "class_id".freeze
#   PERMIT_KEYS = (Rdf::Extensions::QualifiedName::PERMIT_KEYS + [CLASS_ID_KEY]).freeze
#
#   def initialize(document)
#     super
#   end
#
#   def class_id
#     @document[CLASS_ID_KEY]
#   end
#
#   def rdf_class
#     ::Rdf::Class.where(_id: class_id).first
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
#       case object
#       when self
#         mongoize_class(object)
#       when Hash
#         mongoize_hash(object)
#       when String
#         mongoize_string(object)
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
#       def mongoize_class(object)
#         return nil if object.blank?
#         mongoize_hash(object.document.stringify_keys)
#       end
#
#       def mongoize_hash(hash)
#         return nil if hash.blank?
#         hash = hash.stringify_keys.reject { |_, v| v.blank? }.select { |k, _| PERMIT_KEYS.include?(k) }
#         return nil if hash.blank?
#         hash
#       end
#
#       def mongoize_string(string)
#         return nil if string.blank?
#         prefix, name = Rdf::Vocab.qname(string)
#         rdf_class = nil
#         if prefix.present? && name.present? && name != string
#           rdf_class = Rdf::Class.prefix_and_name(prefix, name).first
#         end
#
#         hash = {}
#         hash[Rdf::Extensions::QualifiedName::PREFIX_KEY] = prefix if prefix.present?
#         hash[Rdf::Extensions::QualifiedName::NAME_KEY] = name if name.present? && name != string
#         hash[Rdf::Extensions::QualifiedName::URI_KEY] = string
#         hash[CLASS_ID_KEY] = rdf_class.id if rdf_class.present?
#         hash
#       end
#   end
# end
