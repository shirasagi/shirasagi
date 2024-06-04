require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item) { create :gws_notice_post, folder: folder }
  let(:index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }
  let(:public_index_path) { gws_notice_readables_path(site: site, folder_id: folder, category_id: '-') }
  let(:admin_index_path) { gws_notice_editables_path(site: site, folder_id: folder, category_id: '-') }

  context "with auth" do
    before { login_gws_user }

    it_behaves_like 'crud flow'

    it "#public_index" do
      visit public_index_path
      expect(status_code).to eq 200

      click_link item.name
      expect(status_code).to eq 200
    end

    it "#admin_index" do
      visit admin_index_path
      expect(status_code).to eq 200

      click_link item.name
      expect(status_code).to eq 200
    end
  end

  context "delete_all", js: true do
    before { login_gws_user }

    it do
      visit admin_index_path
      within ".list-items" do
        expect(page).to have_css('.info', text: item.name)
      end

      find("input[value='#{item.id}']").check
      within '.list-head' do
        page.accept_confirm do
          click_button I18n.t('ss.links.delete')
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      # wait to list folders up to protected from spec failure
      within "#content-navi" do
        expect(page).to have_css(".tree-item", text: folder.name)
      end
    end
  end
end
