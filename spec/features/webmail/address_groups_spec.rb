require 'spec_helper'

describe "webmail_address_groups", type: :feature, dbscope: :example do
  let!(:item) { create :webmail_address_group }
  let(:index_path) { webmail_address_groups_path }

  context "with auth", js: true do
    before { login_ss_user }

    it_behaves_like 'crud flow'
  end
end
