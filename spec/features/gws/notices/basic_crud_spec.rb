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
      wait_for_all_turbo_frames
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
      wait_for_all_turbo_frames
      within "#content-navi-core" do
        expect(page).to have_css(".ss-tree-item", text: folder.name)
      end
    end
  end

  context "edit public notice", js: true do
    let(:name) { "name-#{unique_id}" }

    before do
      expect(item.state).to eq "public"
      login_gws_user
    end

    it do
      visit gws_notice_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t('ss.navi.editable')
      end
      within ".list-items" do
        click_on item.name
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t("ss.notice.saved"))

      find("#addon-gws-agents-addons-history").click
      scroll_to_bottom
      wait_for_turbo_frame "#gws-addon-history-frame"
      within "#addon-gws-agents-addons-history table tbody" do
        expect(page.all("tr").count).to be >= 2
      end

      item.reload
      expect(item.name).to eq name
      expect(item.folder_id).to eq folder.id
    end
  end
end
