require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item) { create :gws_notice_post, folder: folder }

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
