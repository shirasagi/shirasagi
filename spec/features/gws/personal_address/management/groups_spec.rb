require 'spec_helper'

describe "gws_personal_address_management_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :webmail_address_group, cur_user: gws_user }
  let(:index_path) { gws_personal_address_management_groups_path(site) }

  context "with auth", js: true do
    before { login_gws_user }

    it_behaves_like 'crud flow'
  end
end
