require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item) { create :gws_notice_post, folder: folder, readable_member_ids: [ gws_user.id ] }

  before { login_gws_user }

  describe "set seen" do
    it do
      visit gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      click_on item.name
      page.accept_confirm do
        click_on I18n.t("gws/notice.links.set_seen")
      end
      within first("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.saved'))
      end

      item.reload
      expect(item.browsed?(gws_user)).to be_truthy

      visit gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      expect(page).to have_no_css(".list-item", text: item.name)
      within "form.index-search" do
        select I18n.t("gws/board.options.browsed_state.read"), from: "s[browsed_state]"
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item", text: item.name)

      visit gws_notice_editables_path(site: site, folder_id: '-', category_id: '-')
      click_on item.name
      within "#addon-gws-agents-addons-notice-member" do
        expect(page).to have_content(I18n.t('gws/board.topic.browsed_user_info.format', count: 1, total: 1))
        click_on I18n.t('gws/board.topic.browsed_user_info.more')
      end
      within "#ajax-box" do
        expect(page).to have_css("tr[data-user-id='#{gws_user.id}']", text: I18n.t('gws/board.options.browsed_state.read'))
      end
    end
  end

  describe "set unseen" do
    before do
      item.set_browsed!(gws_user)
    end

    it do
      visit gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      expect(page).to have_no_link(item.name)
      within "form.index-search" do
        select I18n.t("gws/board.options.browsed_state.read"), from: 's[browsed_state]'
        click_on I18n.t('ss.buttons.search')
      end

      click_on item.name
      page.accept_confirm do
        click_on I18n.t("gws/notice.links.unset_seen")
      end
      within first("#notice", visible: false) do
        expect(page).to have_content(I18n.t('ss.notice.saved'))
      end

      item.reload
      expect(item.browsed?(gws_user)).to be_falsey
    end
  end
end
