require 'spec_helper'

describe SS::MessageEncryptor do
  let(:basic_auth_user) { described_class.encrypt('user') }
  let(:basic_auth_pass) { described_class.encrypt(ss_pass) }

  before do
    SS.config.replace_value_at(:cms, 'basic_auth', [basic_auth_user, basic_auth_pass])
  end

  it 'encrypt' do
    expect(described_class.secret).to eq SS::Crypto.salt[0..31]
    expect(described_class.basic_auth).to eq [basic_auth_user, basic_auth_pass]
    expect(described_class.encryptor.class).to eq ::ActiveSupport::MessageEncryptor
    expect(described_class.http_basic_authentication).to eq %w(user pass)
    expect(described_class.encrypt('user')).not_to eq 'user'
    expect(described_class.encrypt(ss_pass)).not_to eq ss_pass
    expect(described_class.encrypt(%w(user pass))).not_to eq %w(user pass)
    expect(described_class.decrypt(basic_auth_user)).to eq 'user'
    expect(described_class.decrypt(basic_auth_pass)).to eq ss_pass
    expect(described_class.decrypt([basic_auth_user, basic_auth_pass])).to eq %w(user pass)
  end
end
