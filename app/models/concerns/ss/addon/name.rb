# coding: utf-8
class SS::Addon::Name
  def initialize(mod, params = {})
    @klass = mod
    @name  = mod.to_s.underscore.sub("addon/", "")
  end
  
  def klass
    @klass
  end
  
  def name
    I18n.t "modules.addons.#{@name}", default: @name.titleize
  end
  
  def path
    @name.sub("/", "/addons/")#.pluralize
  end
  
  def id
    path.gsub('/', '-')
  end
  
  def exists?(type = :view)
    begin
      klass = "#{path}/#{type}_cell".camelize.constantize
      klass.is_a?(Class)
    rescue => e
      return false
    end
  end
end
