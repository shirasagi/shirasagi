require 'spec_helper'

describe LdapDnValidator, type: :validator do
  let!(:clazz) do
    Struct.new(:dn) do
      include ActiveModel::Validations
      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end
      validates :dn, ldap_dn: true
    end
  end

  context 'with valid dn' do
    subject! { clazz.new("uid=user1, ou=001001政策課, ou=001企画政策部, dc=example, dc=jp") }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with invalid dn' do
    subject! { clazz.new("foo") }

    it do
      expect(subject).to be_invalid
      expect(subject.errors[:dn]).to eq [ I18n.t("errors.messages.invalid") ]
    end
  end
end
