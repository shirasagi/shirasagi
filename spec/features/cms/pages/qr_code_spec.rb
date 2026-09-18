require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  context "qr_code" do
    before { login_cms_user }

    it do
      # new
      visit new_cms_page_path(site.id)
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        within "footer.send" do
          click_button I18n.t("ss.buttons.draft_save")
        end
      end

      wait_for_notice I18n.t("ss.notice.saved")
      item = Cms::Page.last

      # show
      visit cms_page_path(site.id, item.id)
      expect(page).to have_content("sample.html")

      within "#addon-basic" do
        click_on I18n.t('ss.qr_code')
      end
      within_cbox do
        expect(page).to have_selector("td.thumb img")

        wait_for_download("QRCode_160px.png", extname: ".png") do
          find(".qr-png").all("a")[0].click
        end
        wait_for_download("QRCode_240px.png", extname: ".png") do
          find(".qr-png").all("a")[1].click
        end
        wait_for_download("QRCode_480px.png", extname: ".png") do
          find(".qr-png").all("a")[2].click
        end
        wait_for_download("QRCode.svg", extname: ".svg") do
          find(".qr-svg").all("a")[0].click
        end
        wait_for_cbox_closed { find('#cboxClose').click }
      end
    end
  end
end
