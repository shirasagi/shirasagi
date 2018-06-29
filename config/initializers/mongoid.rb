# Require `belongs_to` associations by default. Previous versions had false.
Mongoid::Config.belongs_to_required_by_default = false

#module SkipMongoidQueryCache
#  private
#
#  def system_collection?
#    return true if cache_skip?
#    super
#  end
#
#  def cache_skip?
#    return true if selector.reject { |k, v| k == '_id' }.present?
#    return true if options.reject { |k, v| k == 'limit' }.present?
#  end
#end

#Mongo::Collection::View.__send__(:include, SkipMongoidQueryCache)
