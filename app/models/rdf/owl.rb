# module Rdf::Owl
#   class Restriction
#     include SS::Document
#
#     attr_accessor :in_vocab, :in_class
#     attr_accessor :in_property_namespace, :in_property_prefix, :in_property_name
#
#     field :_id, type: String, default: ->{ property.try(:name) }
#     field :property, type: Rdf::Extensions::Reference::Prop
#     field :datatype, type: Rdf::Extensions::Reference::Class
#     field :cardinality, type: String
#     field :comments, type: Rdf::Extensions::LangHash
#     embedded_in :rdf_class, class_name: "Rdf::Class", inverse_of: :property
#
#     permit_params :in_property_namespace, :in_property_prefix, :in_property_name
#     permit_params :property, :datatype, :cardinality, :comments
#     permit_params comments: Rdf::Extensions::LangHash::LANGS
#
#     before_validation :set_property
#     before_validation :set_id
#     before_validation :set_datatype
#
#     validates :_id, presence: true, uniqueness: true
#     validates :property, presence: true
#     validates :datatype, presence: true
#     validate :validate_property_and_datatype
#
#     before_save :ensure_prop_exist
#
#     class << self
#       def search(params)
#         # criteria = self.where({})
#         # return criteria if params.blank?
#         #
#         # if params[:name].present?
#         #   # criteria = criteria.search_text params[:name]
#         #   words = params[:name]
#         #   words = words.split(/[\s　]+/).uniq.compact.map { |w| /\Q#{w}\E/i } if words.is_a?(String)
#         #   criteria = criteria.all_in(:name => words)
#         # end
#         #
#         # criteria
#         self.where({})
#       end
#     end
#
#     def comment
#       comment = nil
#       if comments.present?
#         comment = comments.preferred_value
#       end
#       if comment.blank? && (prop = property.prop).present?
#         comment = prop.comments.preferred_value
#       end
#       comment
#     end
#
#     private
#       def set_property
#         return if in_property_name.blank?
#         self.property ||= "#{in_vocab.uri}#{in_property_name}"
#       end
#
#       def set_id
#         set_property
#         name = property.try(:name)
#         return if name.blank?
#         self._id ||= name
#       end
#
#       def set_datatype
#         return if datatype.present?
#
#         prop = property.try(:prop)
#         self.datatype ||= prop.ranges.first if prop.present? && prop.ranges.present?
#       end
#
#       def validate_property_and_datatype
#         return if property.blank?
#         return if datatype.blank?
#
#         prop = property.prop
#         if prop.present? && prop.ranges.present?
#           unless prop.ranges.include?(datatype)
#             errors.add(:property, :already_exists_as, range: prop.ranges.first.uri)
#           end
#         end
#       end
#
#       def ensure_prop_exist
#         prop_id = self.property.prop_id
#         return if prop_id.present?
#
#         # create rdf prop if rdf prop is not existed.
#         prop = Rdf::Prop.vocab(in_vocab).where(name: in_property_name).first
#         if prop.blank?
#           prop = Rdf::Prop.create({vocab_id: in_vocab.id,
#                                    name: in_property_name,
#                                    labels: { ja: in_property_name },
#                                    comments: self.comments})
#         end
#
#         copy = {}
#         self.property.each do |k, v|
#           copy[k] = v
#         end
#         copy[Rdf::Extensions::Reference::Prop::PROP_ID_KEY] = prop.id
#         self.property = copy
#       end
#   end
# end
