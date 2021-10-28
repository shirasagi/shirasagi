# Require `belongs_to` associations by default. Previous versions had false.
Mongoid::Config.belongs_to_required_by_default = false

# revert monkey patch
#
# # monkey patch to Mongid::Factory to relax `_type` field treatment.
# #
# # In a standard Mongid::Factory, exception has occurred and stop processing a request
# # if there are no classes matching with `_type` field.
# #
# # But in usual SHIRASAGI cases (especially development),
# # it can sometimes be met the condition described above.
# #
# # This monkey patch relaxes `_type` field treatment not to occur any exceptions.
# #
# module Mongoid
#   module Factory
#     alias build_without_shirasagi build
#     alias from_db_without_shirasagi from_db
#
#     def build(klass, attributes = nil)
#       attributes ||= {}
#       type = attributes[TYPE] || attributes[TYPE.to_sym]
#       if type
#         effective_kass = type.camelize.constantize rescue klass
#       else
#         effective_kass = klass
#       end
#       effective_kass.new(attributes)
#     end
#
#     def from_db(klass, attributes = nil, criteria = nil)
#       selected_fields = criteria.options[:fields] if criteria
#       attributes ||= {}
#       type = attributes[TYPE] || attributes[TYPE.to_sym]
#       if type
#         effective_kass = type.camelize.constantize rescue klass
#       else
#         effective_kass = klass
#       end
#
#       obj = effective_kass.instantiate(attributes, selected_fields)
#       if criteria && criteria.association && criteria.parent_document
#         obj.set_relation(criteria.association.inverse, criteria.parent_document)
#       end
#
#       obj
#     end
#   end
# end
