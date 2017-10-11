require 'spec_helper'

describe "webmail_addresses", type: :feature, dbscope: :example do
  let!(:item) { create :webmail_address }
  let(:index_path) { webmail_addresses_path(account: 0) }

  context "with auth" do
    before { login_ss_user }

    it_behaves_like 'crud flow'
  end
end
