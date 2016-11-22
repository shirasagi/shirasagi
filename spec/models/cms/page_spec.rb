require 'spec_helper'

describe Cms::Page do
  subject(:model) { Cms::Page }
  subject(:factory) { :cms_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }
    let(:show_path) { Rails.application.routes.url_helpers.cms_page_path(site: subject.site, id: subject) }

    it { expect(item.becomes_with_route).not_to eq nil }
    it { expect(item.dirname).to eq nil }
    it { expect(item.basename).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.public?).not_to eq nil }
    it { expect(item.parent).to eq false }
    it { expect(item.private_show_path).to eq show_path }
  end

  describe "#becomes_with_route" do
    subject { create(:cms_page, route: "article/page") }
    it { expect(subject.becomes_with_route).to be_kind_of(Article::Page) }
  end

  describe "#name_for_index" do
    let(:item) { model.last }
    subject { item.name_for_index }

    context "the value is set" do
      before { item.index_name = "Name for index" }
      it { is_expected.to eq "Name for index" }
    end

    context "the value isn't set" do
      it { is_expected.to eq item.name }
    end
  end

  # check_mobile_html_size at addon body
  describe "addon body", js:true do
    let(:site) { cms_site }
    context "check_mobile_html_size" do
      it "on click check_size_button html_size too big" do
        site.mobile_size = 1_024
        site.save!

        login_cms_user
        visit new_cms_page_path(site)

        html_text = ""
        10.times.each do
          html_text += "<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>"
        end

        fill_in_ckeditor "item_html", with: html_text
        click_on I18n.t("cms.mobile_size_check")
        sleep 1
        expect(page).to have_css "form #errorMobileChecker"
        expect(page).to have_selector "form #errorMobileChecker p.error", text: /携帯で表示する場合、本文のデータサイズが(.+)/i
      end

      it "on click check_size_button html_size ok" do

        html_text = "<p>あいうえおカキクケコ</p>"

        login_cms_user
        visit new_cms_page_path(site)

        fill_in_ckeditor "item_html", with: html_text
        click_on I18n.t("cms.mobile_size_check")
        sleep 1

        expect(page).to have_css "form #errorMobileChecker"
        expect(page).to have_selector "form #errorMobileChecker p", text: I18n.t('errors.messages.mobile_size_check_size')
      end
    end

    context "check_file_size" do
      let(:file) { create(:ss_file, filename: "logo.png") }
      let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }

      it "mobile_size 1" do
        site.mobile_state = "enabled"
        site.mobile_size = 1_024
        site.save!

        html_text = ""
        html_text += "<img src=\"/fs/#{file.id}/_/logo.png\">"

        login_cms_user
        visit new_cms_page_path(site)

        fill_in_ckeditor "item_html", with: html_text
        click_on I18n.t("cms.mobile_size_check")
        sleep 1

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

        fill_in_ckeditor "item_html", with: html_text
        click_on I18n.t("cms.mobile_size_check")
        sleep 1
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

        fill_in_ckeditor "item_html", with: html_text
        click_on I18n.t("cms.mobile_size_check")
        sleep 1
        expect(page).to have_selector "#errorMobileChecker p", text: I18n.t('errors.messages.mobile_size_check_size')

        3.times.each do
          html_text += "<img src=\"/fs/#{file.id}/_/logo.png\">"
        end

        fill_in_ckeditor "item_html", with: html_text
        click_on I18n.t("cms.mobile_size_check")
        sleep 1
        expect(page).to have_selector "#errorMobileChecker p", text: I18n.t('errors.messages.mobile_size_check_size')

      end

      it "many different files in html" do

        site.mobile_state = "enabled"
        site.mobile_size = 20 * 1_024
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

        fill_in_ckeditor "item_html", with: html_text
        click_on I18n.t("cms.mobile_size_check")
        sleep 1
        expect(page).to have_selector "form #errorMobileChecker p", text: /携帯電話で表示する場合、ファイルサイズ合計(.+)/i
      end
    end
  end
  def fill_in_ckeditor(locator, opts)
    content = opts.fetch(:with).to_json
    page.execute_script <<-SCRIPT
      $('textarea##{locator}').text(#{content});
      CKEDITOR.instances['#{locator}'].setData(#{content});
    SCRIPT

    sleep 1
  end

end
