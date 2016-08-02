# class Rdf::Extensions::Reference::PropArray < Array
#   class << self
#     # Get the object as it was stored in the database, and instantiate
#     # this custom class from it.
#     def demongoize(object)
#       return nil if object.nil?
#       self.new(demongoize_array(object))
#     end
#
#     # Takes any possible object and converts it to how it would be
#     # stored in the database.
#     def mongoize(object)
#       return nil if object.nil?
#       mongoize_array(object)
#     end
#
#     # Converts the object that was supplied to a criteria and converts it
#     # into a database friendly form.
#     def evolve(object)
#       object
#     end
#
#     private
#     def demongoize_array(array)
#       array.map do |hash|
#         Rdf::Extensions::Reference::Prop.demongoize(hash)
#       end
#     end
#
#     def mongoize_array(array)
#       return nil if array.blank?
#       array = array.select(&:present?).map do |hash|
#         Rdf::Extensions::Reference::Prop.mongoize(hash)
#       end
#       array.compact
#     end
#   end
#
#   def include?(rhs)
#     found = false
#     self.each do |lhs|
#       if lhs.uri == rhs.uri
#         found = true
#         break
#       end
#     end
#     found
#   end
# end
