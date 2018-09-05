require 'spec_helper'

describe "webmail_group_signatures", type: :feature, dbscope: :example do
  let(:group) { create :webmail_group }
  let!(:item) { create :webmail_signature }
  let(:index_path) { webmail_group_signatures_path(group: group) }

  context "with auth" do
    before { login_ss_user }

    it_behaves_like 'crud flow'
  end
end
