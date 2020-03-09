require 'spec_helper'

describe SS::MessageEncryptor do
  let(:basic_auth_user) { described_class.encrypt('user') }
  let(:basic_auth_pass) { described_class.encrypt('pass') }

  before do
    SS::Config.replace_value_at(:cms, 'basic_auth', [basic_auth_user, basic_auth_pass])
  end

  it 'encrypt' do
    expect(described_class.secret).to eq Rails.application.secrets[:secret_key_base][0..31]
    expect(described_class.basic_auth).to eq [basic_auth_user, basic_auth_pass]
    expect(described_class.encryptor.class).to eq ::ActiveSupport::MessageEncryptor
    expect(described_class.http_basic_authentication).to eq %w(user pass)
    expect(described_class.encrypt('user')).not_to eq 'user'
    expect(described_class.encrypt('pass')).not_to eq 'pass'
    expect(described_class.encrypt(%w(user pass))).not_to eq %w(user pass)
    expect(described_class.decrypt(basic_auth_user)).to eq 'user'
    expect(described_class.decrypt(basic_auth_pass)).to eq 'pass'
    expect(described_class.decrypt([basic_auth_user, basic_auth_pass])).to eq %w(user pass)
  end
end
