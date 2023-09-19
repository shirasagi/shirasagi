require 'spec_helper'

describe "gws_notices_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:folder) { create(:gws_notice_folder) }
  let(:index_path) { gws_notice_readables_path(site: site, folder_id: folder, category_id: '-') }

  let(:browsed) { { user.id => Time.zone.now.utc } }
  let!(:item1) { create :gws_notice_post, folder: folder }
  let!(:item2) { create :gws_notice_post, folder: folder, severity: "high" }
  let!(:item3) { create :gws_notice_post, folder: folder, browsed_users_hash: browsed }
  let!(:item4) { create :gws_notice_post, folder: folder, severity: "high", browsed_users_hash: browsed }

  before do
    site.notice_browsed_state = "both"
    site.update!
  end

  context "with auth" do
    before { login_gws_user }

    context "default toggled by button" do
      it "#index" do
        visit index_path
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        within ".tree-navi" do
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end

        within ".list-items" do
          click_on item1.name
        end
        page.accept_confirm do
          click_on I18n.t("gws/notice.links.set_seen")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end

        expect(page).to have_css(".list-item.read", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        within ".tree-navi" do
          expect(page).to have_css('.tree-item.is-current', text: folder.name)
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end
      end
    end

    context "default toggled by read" do
      before do
        site.notice_toggle_browsed = "read"
        site.update!
      end

      it "#index" do
        visit index_path
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        within ".tree-navi" do
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end

        within ".list-items" do
          click_on item1.name
        end
        expect(page).to have_button(I18n.t("gws/notice.links.unset_seen"))
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end

        expect(page).to have_css(".list-item.read", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        within ".tree-navi" do
          expect(page).to have_css('.tree-item.is-current', text: folder.name)
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end
      end

      it "#index" do
        visit index_path
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        within ".tree-navi" do
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end

        within ".list-items" do
          click_on item1.name
        end
        expect(page).to have_button(I18n.t("gws/notice.links.unset_seen"))

        page.accept_confirm do
          click_on I18n.t("gws/notice.links.unset_seen")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        within ".nav-menu" do
          click_on I18n.t("ss.links.back_to_index")
        end

        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        # wait for ajax completion
        within ".tree-navi" do
          expect(page).to have_css('.tree-item.is-current', text: folder.name)
          expect(page).to have_css('.content-navi-refresh', text: "refresh")
        end
      end
    end
  end
end
