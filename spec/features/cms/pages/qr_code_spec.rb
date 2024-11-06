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
      wait_for_cbox do
        expect(page).to have_selector("td.thumb img")

        find(".qr-png").all("a")[0].click
        wait_for_download
        find(".qr-png").all("a")[1].click
        wait_for_download
        find(".qr-png").all("a")[2].click
        wait_for_download
        find(".qr-svg").all("a")[0].click
        wait_for_download
        sleep(1)

        expect(::File.basename(downloads[0])).to eq "QRCode.svg"
        expect(::File.basename(downloads[1])).to eq "QRCode_160px.png"
        expect(::File.basename(downloads[2])).to eq "QRCode_240px.png"
        expect(::File.basename(downloads[3])).to eq "QRCode_480px.png"
        wait_cbox_close { find('#cboxClose').click }
      end
    end
  end
end
