require 'spec_helper'

describe "gws_roles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_role }
  let(:index_path) { gws_roles_path site }

  context "with auth" do
    before { login_gws_user }

    it_behaves_like 'crud flow'
  end
end
