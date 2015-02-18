class Ldap::User < Ldap::Entry
  def initialize(connection, entry)
    super(connection, entry)
  end

  def authenticate(password)
    config = @connection.config.to_h.merge({ username: dn, password: password })
    new_connection = Ldap::Connection.connect(config) rescue nil
    new_connection.present?
  end
end

class Ldap::InetOrgPerson < Ldap::User
  public_class_method :new

  def name
    value(:cn)
  end

  def uid
    value(:uid)
  end

  def email
    value(:mail)
  end

  def self.support?(object_classes)
    object_classes.include?("inetOrgPerson")
  end

  def self.filter
    Net::LDAP::Filter.construct("(objectClass=inetOrgPerson)")
  end
end

# class Ldap::PosixAccount < Ldap::User
#   public_class_method :new
#
#   def name
#     value(:cn)
#   end
#
#   def uid
#     value(:uid)
#   end
#
#   def email
#     value(:mail)
#   end
#
#   def self.support?(object_classes)
#     object_classes.include?("posixAccount")
#   end
#
#   def self.filter
#     Net::LDAP::Filter.construct("(objectClass=posixAccount)")
#   end
# end

class Ldap::User
  private_class_method :new

  # CONCRETE_CLASSES = [ Ldap::InetOrgPerson, Ldap::PosixAccount ].freeze
  CONCRETE_CLASSES = [ Ldap::InetOrgPerson ].freeze

  DEFAULT_FILTER = CONCRETE_CLASSES.map { |c| c.filter }.reduce { |a, e| a | e }

  def self.create(connection, entry)
    object_classes = Ldap::Entry.normalize(entry[:objectClass])
    CONCRETE_CLASSES.each do |c|
      return c.new(connection, entry) if c.support?(object_classes)
    end
    Rails.logger.info("unknown object class: #{object_classes}")
    nil
  end
end
