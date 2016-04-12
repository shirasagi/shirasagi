class Ldap::GroupBase < Ldap::Entry
  def initialize(connection, entry)
    super(connection, entry)
  end
end

class Ldap::OrganizationalUnit < Ldap::GroupBase
  def name
    value(:ou)
  end

  def contact_tel
    value(:telephoneNumber)
  end

  def self.support?(object_classes)
    object_classes.include?("organizationalUnit")
  end

  def self.filter
    Net::LDAP::Filter.construct("(objectClass=organizationalUnit)")
  end
end

class Ldap::Organization < Ldap::GroupBase
  def name
    value(:o)
  end

  def contact_tel
    value(:telephoneNumber)
  end

  def self.support?(object_classes)
    object_classes.include?("organization")
  end

  def self.filter
    Net::LDAP::Filter.construct("(objectClass=organization)")
  end
end

# class Ldap::PosixGroup < Ldap::Group
#   public_class_method :new
#
#   def name
#     value(:cn)
#   end
#
#   def contact_tel
#     nil
#   end
#
#   def self.support?(object_classes)
#     object_classes.include?("posixGroup")
#   end
#
#   def self.filter
#     Net::LDAP::Filter.construct("(objectClass=posixGroup)")
#   end
#
#   def users
#     self[:memberuid].uniq.map do |memberuid|
#       filter = Net::LDAP::Filter.construct("(&(objectClass=posixAccount)(uid=#{memberuid}))")
#       @connection.search(filter, scope: Net::LDAP::SearchScope_WholeSubtree).map do |e|
#         Ldap::User.create(@connection, e)
#       end
#     end.uniq.flatten
#   end
# end

class Ldap::GroupBase
  # CONCRETE_CLASSES = [ Ldap::OrganizationalUnit, Ldap::Organization, Ldap::PosixGroup ].freeze
  CONCRETE_CLASSES = [ Ldap::OrganizationalUnit, Ldap::Organization ].freeze

  DEFAULT_FILTER = CONCRETE_CLASSES.map { |c| c.filter }.reduce { |a, e| a | e }

  def groups
    @connection.search(DEFAULT_FILTER, base: dn).map do |e|
      self.class.create(@connection, e)
    end
  end

  def users
    @connection.search(Ldap::User::DEFAULT_FILTER, base: dn).map do |e|
      Ldap::User.create(@connection, e)
    end
  end

  def self.create(connection, entry)
    object_classes = Ldap::Entry.normalize(entry[:objectClass])
    CONCRETE_CLASSES.each do |c|
      return c.new(connection, entry) if c.support?(object_classes)
    end
    Rails.logger.info("unknown object class: #{object_classes}")
    nil
  end
end

class Ldap::Group < Ldap::GroupBase
  private_class_method :new
end
