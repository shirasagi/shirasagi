class Cms::Ldap::Extensions::LdapEntity < Hash
  def mongoize
    self.to_h
  end

  class << self
    def demongoize(object)
      if object.present?
        ret = Cms::Ldap::Extensions::LdapEntity.new
        object.symbolize_keys.each do |key, value|
          ret[key] = value
        end
        ret
      else
        Cms::Ldap::Extensions::LdapEntity.new
      end
    end

    def mongoize(object)
      case object
      when self.class
        object.mongoize
      when Hash
        object.symbolize_keys
      else
        object
      end
    end

    def convert_group(ldap_group, parent_dn: nil)
      entity = new
      entity[:type] = Cms::Ldap::Import::TYPE_GROUP
      entity[:dn] = ldap_group.dn
      entity[:name] = ldap_group.name
      entity[:contact_tel] = ldap_group.contact_tel
      entity[:parent_dn] = parent_dn if parent_dn.present?
      entity
    end

    def convert_user(ldap_user, parent_dn: nil)
      entity = new
      entity[:type] = Cms::Ldap::Import::TYPE_USER
      entity[:dn] = ldap_user.dn
      entity[:name] = ldap_user.name
      entity[:uid] = ldap_user.uid
      entity[:email] = ldap_user.email
      entity[:parent_dn] = parent_dn if parent_dn.present?
      entity
    end
  end

  def type
    self[:type]
  end

  def dn
    self[:dn]
  end

  def name
    self[:name]
  end

  def uid
    self[:uid]
  end

  def email
    self[:email]
  end

  def contact_tel
    self[:contact_tel]
  end

  def contact_fax
    nil
  end

  alias contact_email email
end
