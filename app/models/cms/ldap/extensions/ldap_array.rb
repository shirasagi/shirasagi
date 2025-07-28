class Cms::Ldap::Extensions::LdapArray < Array
  def mongoize
    self.map do |e|
      if e.respond_to?(:mongoize)
        e.mongoize
      elsif e.respond_to?(:to_h)
        e.to_h
      else
        e
      end
    end
  end

  class << self
    def demongoize(object)
      if object.present?
        # Ldap::Extensions::LdapArray.new(normalize(object))
        object.reduce(Cms::Ldap::Extensions::LdapArray.new) do |a, e|
          a << Cms::Ldap::Extensions::LdapEntity.demongoize(e)
        end
      else
        Cms::Ldap::Extensions::LdapArray.new
      end
    end

    def mongoize(object)
      case object
      when self.class
        object.mongoize
      when Array
        new(normalize(object)).mongoize
      else
        object
      end
    end

    private

    def normalize(array)
      array.map do |hash|
        Cms::Ldap::Extensions::LdapEntity.demongoize hash
      end
    end
  end

  def root_groups
    child_groups(nil)
  end

  def child_groups(parent_dn)
    self.select do |e|
      e[:parent_dn] == parent_dn && e[:type] == Cms::Ldap::Import::TYPE_GROUP
    end
  end

  def child_users(parent_dn)
    self.select do |e|
      e[:parent_dn] == parent_dn && e[:type] == Cms::Ldap::Import::TYPE_USER
    end
  end
end
