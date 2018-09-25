require 'spec_helper'

describe "webmail_signatures", type: :feature, dbscope: :example do
  let!(:item) { create :webmail_signature, cur_user: webmail_user }
  let(:index_path) { webmail_signatures_path(account: 0) }

  context "with auth" do
    before { login_webmail_user }

    it_behaves_like 'crud flow'
  end
end
