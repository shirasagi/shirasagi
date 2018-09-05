require 'spec_helper'

describe "webmail_group_address_groups", type: :feature, dbscope: :example do
  let(:group) { create :webmail_group }
  let!(:item) { create :webmail_address_group }
  let(:index_path) { webmail_group_address_groups_path(group: group) }

  context "with auth", js: true do
    before { login_ss_user }

    it_behaves_like 'crud flow'
  end
end
