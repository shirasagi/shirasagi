require 'spec_helper'

describe LdapFilterValidator, type: :validator do
  let!(:clazz) do
    Struct.new(:filter) do
      include ActiveModel::Validations
      def self.model_name
        ActiveModel::Name.new(self, nil, "temp")
      end
      validates :filter, ldap_filter: true
    end
  end

  context 'with valid filter' do
    subject! { clazz.new("(objectclass=*)") }

    it do
      expect(subject).to be_valid
    end
  end

  context 'with invalid dn' do
    subject! { clazz.new("(!(objectclass=*)(objectclass=*))") }

    it do
      expect(subject).to be_invalid
      expect(subject.errors[:filter]).to eq [ I18n.t("errors.messages.invalid") ]
    end
  end
end
