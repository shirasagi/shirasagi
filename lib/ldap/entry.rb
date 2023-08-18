class Ldap::Entry
  include Enumerable
  include Comparable

  def initialize(connection, entry)
    @connection = connection
    @entry = entry
  end

  class << self
    def find(connection, ldap_dn)
      connection.find(ldap_dn, self)
    end
  end

  def dn
    self.class.normalize(@entry.dn)
  end

  def [](name)
    self.class.normalize(@entry[name])
  end

  alias values []

  def value(name)
    self[name].first
  end

  def each
    @entry.each do |key, values|
      yield self.class.normalize(key), self.class.normalize(values)
    end
  end

  def parent
    _, parent_dn = Ldap::Connection.split_dn(dn)
    Ldap::Group.find(@connection, parent_dn)
  end

  def self.normalize(value)
    if value.kind_of?(String)
      value.force_encoding("UTF-8")
    elsif value.kind_of?(Array)
      value.map do |v|
        normalize(v)
      end
    else
      value
    end
  end

  def <=>(other)
    dn <=> other.dn
  end
end
