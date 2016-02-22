class Ldap::Entry
  include Enumerable
  include Comparable

  def initialize(connection, entry)
    @connection = connection
    @entry = entry
  end

  class << self
    def find(connection, dn)
      connection.find(dn, self)
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

  def self.normalize(e)
    if e.kind_of?(String)
      e.force_encoding("UTF-8")
    elsif e.kind_of?(Array)
      e.map do |v|
        normalize(v)
      end
    else
      e
    end
  end

  def <=>(other)
    dn <=> other.dn
  end
end
