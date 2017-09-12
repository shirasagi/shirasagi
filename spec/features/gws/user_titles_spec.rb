require 'spec_helper'

describe "gws_user_titles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :ss_user_title, group_id: gws_user.group_ids.first }
  let(:index_path) { gws_user_titles_path site }

  context "with auth" do
    before { login_gws_user }

    it_behaves_like 'crud flow'
  end
end
