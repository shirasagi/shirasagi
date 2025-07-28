class LdapFilterValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    require 'net/ldap/dn'
    Net::LDAP::Filter.construct(value)
  rescue
    record.errors.add(attribute, options[:message] || :invalid)
  end
end
