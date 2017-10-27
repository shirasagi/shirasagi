require 'spec_helper'

describe "webmail_signatures", type: :feature, dbscope: :example do
  let!(:item) { create :webmail_signature }
  let(:index_path) { webmail_signatures_path(account: 0) }

  context "with auth" do
    before { login_ss_user }

    it_behaves_like 'crud flow'
  end
end
