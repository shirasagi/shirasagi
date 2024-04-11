class LdapDnValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    require 'net/ldap/dn'
    Net::LDAP::DN.new(value).to_a
  rescue
    record.errors.add(attribute, options[:message] || :invalid)
  end
end
