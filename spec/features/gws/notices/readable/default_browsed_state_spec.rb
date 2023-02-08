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

  context "with auth" do
    before { login_gws_user }

    context "default unread" do
      it "#index" do
        expect(site.notice_browsed_state).to eq "unread"

        visit index_path
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_no_css(".list-item.read", text: item3.name)
        expect(page).to have_no_css(".list-item.read", text: item4.name)

        within ".index-search" do
          select I18n.t("gws/board.options.browsed_state.both"), from: "s[browsed_state]"
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)
      end
    end

    context "default both" do
      before do
        site.notice_browsed_state = "both"
        site.update!
      end

      it "#index" do
        visit index_path
        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)
      end
    end

    context "default read" do
      before do
        site.notice_browsed_state = "read"
        site.update!
      end

      it "#index" do
        visit index_path
        expect(page).to have_no_css(".list-item.unread", text: item1.name)
        expect(page).to have_no_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)

        within ".index-search" do
          select I18n.t("gws/board.options.browsed_state.both"), from: "s[browsed_state]"
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item.unread", text: item1.name)
        expect(page).to have_css(".list-item.unread", text: item2.name)
        expect(page).to have_css(".list-item.read", text: item3.name)
        expect(page).to have_css(".list-item.read", text: item4.name)
      end
    end
  end
end
