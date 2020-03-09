require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }

  # check_mobile_html_size at addon body
  context "check_mobile_html_size" do
    it "on click check_size_button html_size too big", fragile: true do
      site.mobile_size = 1_024
      site.save!

      login_cms_user
      visit new_cms_page_path(site)

      html_text = "<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>" * 10

      fill_in_ckeditor "item[html]", with: html_text
      click_on I18n.t("cms.mobile_size_check")
      expect(page).to have_css "form #errorMobileChecker"
      expect(page).to have_selector "form #errorMobileChecker p.error", text: /携帯で表示する場合、本文のデータサイズが(.+)/i
    end

    it "on click check_size_button html_size ok" do

      html_text = "<p>あいうえおカキクケコ</p>"

      login_cms_user
      visit new_cms_page_path(site)

      fill_in_ckeditor "item[html]", with: html_text
      click_on I18n.t("cms.mobile_size_check")

      expect(page).to have_css "form #errorMobileChecker"
      expect(page).to have_selector "form #errorMobileChecker p", text: I18n.t('errors.messages.mobile_size_check_size')
    end
  end

  context "check_file_size" do
    let(:file) { create(:ss_file, filename: "logo.png") }
    let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }

    it "mobile_size 1", fragile: true do
      site.mobile_state = "enabled"
      site.mobile_size = 1_024
      site.save!

      html_text = "<img src=\"/fs/#{file.id}/_/logo.png\">"

      login_cms_user
      visit new_cms_page_path(site)

      fill_in_ckeditor "item[html]", with: html_text
      click_on I18n.t("cms.mobile_size_check")

      expect(page).to have_css "form #errorMobileChecker"
      expect(page).to have_selector "form #errorMobileChecker p", text: /携帯電話で表示する場合、ファイルサイズ合計(.+)/i
    end

    it "mobile_size 100" do
      site.mobile_state = "enabled"
      site.mobile_size = 100 * 1_024
      site.save!
      site.reload

      html_text = ""
      html_text += "<img src=\"/fs/#{file.id}/_/logo.png\">"

      login_cms_user
      visit new_cms_page_path(site)

      fill_in_ckeditor "item[html]", with: html_text
      click_on I18n.t("cms.mobile_size_check")
      expect(page).to have_selector "form #errorMobileChecker p", text: I18n.t('errors.messages.mobile_size_check_size')
    end

    it "many same files in html" do

      site.mobile_state = "enabled"
      site.mobile_size = 20 * 1_024
      site.save!
      site.reload

      html_text = ""
      html_text += "<img src=\"/fs/#{file.id}/_/logo.png\">"

      login_cms_user
      visit new_cms_page_path(site)

      fill_in_ckeditor "item[html]", with: html_text
      click_on I18n.t("cms.mobile_size_check")
      expect(page).to have_selector "#errorMobileChecker p", text: I18n.t('errors.messages.mobile_size_check_size')

      3.times.each do
        html_text += "<img src=\"/fs/#{file.id}/_/logo.png\">"
      end

      fill_in_ckeditor "item[html]", with: html_text
      click_on I18n.t("cms.mobile_size_check")
      expect(page).to have_selector "#errorMobileChecker p", text: I18n.t('errors.messages.mobile_size_check_size')
    end

    it "many different files in html", fragile: true do

      site.mobile_state = "enabled"
      site.mobile_size = 6 * 1_024
      site.save!
      site.reload

      file2 = tmp_ss_file(
        Cms::File, site: site, user: cms_user, model: "cms/file",
        contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      )

      html_text = ""
      html_text += "<img src=\"/fs/#{file.id}/_/logo.png\">"
      html_text += "<img src=\"/fs/#{file2.id}/_/keyvisual.jpg\">"

      login_cms_user
      visit new_cms_page_path(site)

      fill_in_ckeditor "item[html]", with: html_text
      click_on I18n.t("cms.mobile_size_check")
      expect(page).to have_selector "form #errorMobileChecker p", text: /携帯電話で表示する場合、ファイルサイズ合計(.+)/i
    end

    it "mobile_state disabled" do
      site.mobile_state = "disabled"
      site.save!

      login_cms_user
      visit new_cms_page_path(site)

      expect(page).to have_no_text(I18n.t("cms.mobile_size_check"))
    end
  end
end
