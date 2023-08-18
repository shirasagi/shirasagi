require 'spec_helper'

describe "webmail_address_groups", type: :feature, dbscope: :example do
  let!(:item) { create :webmail_address_group, cur_user: webmail_user }
  let(:index_path) { webmail_address_groups_path }

  context "with auth" do
    before { login_webmail_user }

    it_behaves_like 'crud flow'
  end
end
