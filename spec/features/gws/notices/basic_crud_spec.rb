require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item) { create :gws_notice_post, folder: folder }
  let(:index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }
  let(:public_index_path) { gws_notice_readables_path(site: site, folder_id: folder, category_id: '-') }

  context "with auth" do
    before { login_gws_user }

    it_behaves_like 'crud flow'

    it "#public_index" do
      visit public_index_path
      expect(status_code).to eq 200

      click_link item.name
      expect(status_code).to eq 200
    end
  end
end
