require 'spec_helper'

describe "cms_pages" do
  subject(:site) { cms_site }
  subject(:item) { Cms::Page.last }
  subject(:index_path) { cms_pages_path site.id }
  subject(:new_path) { new_cms_page_path site.id }
  subject(:show_path) { cms_page_path site.id, item }
  subject(:edit_path) { edit_cms_page_path site.id, item }
  subject(:delete_path) { delete_cms_page_path site.id, item }
  subject(:move_path) { move_cms_page_path site.id, item }
  subject(:copy_path) { copy_cms_page_path site.id, item }
  subject(:contains_urls_path) { contains_urls_cms_page_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#move" do
      visit move_path
      within "form" do
        fill_in "destination", with: "destination"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "destination.html")

      within "form" do
        fill_in "destination", with: "sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] modify")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end

    it "#contains_urls" do
      visit contains_urls_path
      expect(status_code).to eq 200
    end
  end

  # check_mobile_html_size at addon body
  describe "addon body", js: true do
    let(:site) { cms_site }

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

        file2 = Cms::File.new model: "cms/file", site_id: site.id
        file_path = Rails.root.join("spec", "fixtures", "ss", "file", "keyvisual.jpg")
        Fs::UploadedFile.create_from_file(file_path, basename: "spec") do |test_file|
          file2.in_file = test_file
          file2.save!
        end

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
end
