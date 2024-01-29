require 'spec_helper'

describe "gws_notices_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:folder) { create(:gws_notice_folder) }
  let(:index_path) { gws_notice_readables_path(site: site, folder_id: folder, category_id: '-') }

  let!(:item1) { create :gws_notice_post, folder: folder }
  let!(:item2) { create :gws_notice_post, folder: folder, severity: "high" }

  context "with auth" do
    before { login_gws_user }

    context "default all" do
      it "#index" do
        visit index_path
        expect(page).to have_css("#content-navi .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)

        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')
      end
    end

    context "default high" do
      before do
        site.notice_severity = "high"
        site.update!
      end

      it "#index" do
        visit index_path
        expect(page).to have_css("#content-navi .content-navi-refresh", text: "refresh")
        expect(page).to have_no_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)

        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".index-search" do
          select I18n.t("gws/notice.options.severity.all"), from: "s[severity]"
          click_on I18n.t("ss.buttons.search")
        end

        # wait for ajax completion
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)

        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')
      end
    end

    context "default high" do
      before do
        site.notice_severity = "normal"
        site.update!
      end

      it "#index" do
        visit index_path
        expect(page).to have_css("#content-navi .content-navi-refresh", text: "refresh")
        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_no_css(".list-item", text: item2.name)

        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')

        within ".index-search" do
          select I18n.t("gws/notice.options.severity.all"), from: "s[severity]"
          click_on I18n.t("ss.buttons.search")
        end

        expect(page).to have_css(".list-item", text: item1.name)
        expect(page).to have_css(".list-item", text: item2.name)

        # wait for ajax completion
        expect(page).to have_no_css('.fc-loading')
        expect(page).to have_no_css('.ss-base-loading')
      end
    end
  end
end
