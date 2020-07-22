require 'spec_helper'

describe "link_checker", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) do
    create_once :article_node_page, filename: "docs", name: "article",
    group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: [cms_group.id]) }
  let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }

  let(:ss_file1) { create :ss_file, site: site, user: user }
  let(:ss_file2) { create :ss_file, site: site, user: user }

  let(:success_url1) { ss_file1.url }
  let(:success_url2) { ::File.join(site.full_url, ss_file2.url) }
  let(:success_url3) { "https://success.example.jp" }

  let(:failed_url1) { "/fs/1/_/failed.txt" }
  let(:failed_url2) { ::File.join(site.full_url, "/fs/2/_/2.pdf") }
  let(:failed_url3) { "https://failed.example.jp" }

  let(:invalid_url1) { "https://invalid.example.jp /" }

  let(:redirection_url0) { "https://redirection-0.example.jp/" }
  let(:redirection_url1) { "http://redirection-1.example.jp/" }
  let(:redirection_url2) { "https://redirection-2.example.jp/" }
  let(:redirection_url3) { "http://redirection-3.example.jp/" }
  let(:redirection_url4) { "https://redirection-4.example.jp/" }
  let(:redirection_url5) { "http://redirection-5.example.jp/" }
  let(:redirection_self_url) { "https://redirection-self.example.jp/" }

  let(:success) { I18n.t("errors.messages.link_check_success") }
  let(:failure) { I18n.t("errors.messages.link_check_failure") }

  let(:edit_path) { edit_article_page_path site.id, node, item }

  before do
    stub_request(:get, success_url3).to_return(body: "", status: 200, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, failed_url3).to_return(body: "", status: 404, headers: { 'Content-Type' => 'text/html' })

    stub_request(:get, redirection_url0).to_return(body: "", status: 200, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, redirection_url1).to_return(status: 302, headers: { 'Location' => redirection_url0, 'Content-Type' => 'text/html' })
    stub_request(:get, redirection_url2).to_return(status: 302, headers: { 'Location' => redirection_url1, 'Content-Type' => 'text/html' })
    stub_request(:get, redirection_url3).to_return(status: 302, headers: { 'Location' => redirection_url2, 'Content-Type' => 'text/html' })
    stub_request(:get, redirection_url4).to_return(status: 302, headers: { 'Location' => redirection_url3, 'Content-Type' => 'text/html' })
    stub_request(:get, redirection_url5).to_return(status: 302, headers: { 'Location' => redirection_url4, 'Content-Type' => 'text/html' })
    stub_request(:get, redirection_self_url).to_return(status: 302, headers: { 'Location' => redirection_self_url, 'Content-Type' => 'text/html' })

    Capybara.app_host = "http://#{site.domain}"

    login_cms_user
  end

  context "check links" do
    context "with cms addon body" do
      let(:item) { create :article_page, cur_node: node, file_ids: [ss_file1.id, ss_file2.id], state: "public" }
      let(:html) do
        h = []
        h << "<a class=\"icon-png\" href=\"#{success_url1}\">#{success_url1}</a>"
        h << "<a href=\"#{success_url2}\">#{success_url2}</a>"
        h << "<a href=\"#{success_url3}\">#{success_url3}</a>"
        h << "<a class=\"icon-png\" href=\"#{failed_url1}\">#{failed_url1}</a>"
        h << "<a href=\"#{failed_url2}\">#{failed_url2}</a>"
        h << "<a href=\"#{failed_url3}\">#{failed_url3}</a>"
        h << "<a href=\"#{invalid_url1}\">#{invalid_url1}</a>"
        h.join
      end

      it "publish" do
        visit edit_path
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        article = Article::Page.first
        expect(article.public?).to be_truthy
        expect(article.files[0].public?).to be_truthy
        expect(article.files[1].public?).to be_truthy

        visit edit_path
        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html
          click_button I18n.t("cms.link_check")
          wait_for_ajax

          success_full_url1 = ::File.join(site.full_url, success_url1)
          failed_full_url1 = ::File.join(site.full_url, failed_url1)
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{invalid_url1}")
        end
      end

      it "draft_save" do
        visit edit_path
        within "form#item-form" do
          click_on I18n.t("ss.buttons.draft_save")
        end
        click_on I18n.t("ss.buttons.ignore_alert")
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        article = Article::Page.first
        expect(article.public?).to be_falsey
        expect(article.files[0].public?).to be_falsey
        expect(article.files[1].public?).to be_falsey

        visit edit_path
        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html
          click_button I18n.t("cms.link_check")
          wait_for_ajax

          success_full_url1 = ::File.join(site.full_url, success_url1)
          failed_full_url1 = ::File.join(site.full_url, failed_url1)
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{invalid_url1}")
        end
      end
    end

    context "with entry form" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file1.id, ss_file2.id], form_id: form.id }
      let(:html) do
        h = []
        h << "<a class=\"icon-png\" href=\"#{success_url1}\">#{success_url1}</a>"
        h << "<a href=\"#{success_url2}\">#{success_url2}</a>"
        h << "<a href=\"#{success_url3}\">#{success_url3}</a>"
        h << "<a class=\"icon-png\" href=\"#{failed_url1}\">#{failed_url1}</a>"
        h << "<a href=\"#{failed_url2}\">#{failed_url2}</a>"
        h << "<a href=\"#{failed_url3}\">#{failed_url3}</a>"
        h << "<a href=\"#{invalid_url1}\">#{invalid_url1}</a>"
        h.join
      end

      it "publish" do
        visit edit_path
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        article = Article::Page.first
        expect(article.public?).to be_truthy
        expect(article.files[0].public?).to be_truthy
        expect(article.files[1].public?).to be_truthy

        visit edit_path
        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.link_check")
          wait_for_ajax

          success_full_url1 = ::File.join(site.full_url, success_url1)
          failed_full_url1 = ::File.join(site.full_url, failed_url1)
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{invalid_url1}")
        end
      end

      it "draft_save" do
        visit edit_path
        within "form#item-form" do
          click_on I18n.t("ss.buttons.draft_save")
        end
        click_on I18n.t("ss.buttons.ignore_alert")
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        article = Article::Page.first
        expect(article.public?).to be_falsey
        expect(article.files[0].public?).to be_falsey
        expect(article.files[1].public?).to be_falsey

        visit edit_path
        within ".column-value-palette" do
          click_on column.name
        end
        within ".column-value-cms-column-free" do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html
        end
        within "#addon-cms-agents-addons-form-page" do
          click_button I18n.t("cms.link_check")
          wait_for_ajax

          success_full_url1 = ::File.join(site.full_url, success_url1)
          failed_full_url1 = ::File.join(site.full_url, failed_url1)
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{success_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_full_url1}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url2}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{failed_url3}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{invalid_url1}")
        end
      end
    end

    context "with redirection url" do
      let(:item) { create :article_page, cur_node: node, file_ids: [ss_file1.id, ss_file2.id], state: "public" }
      let(:html) do
        h = []
        h << "<a href=\"#{redirection_url5}\">#{redirection_url5}</a>"
        h << "<a href=\"#{redirection_self_url}\">#{redirection_self_url}</a>"
        h.join
      end

      it do
        visit edit_path
        within "#addon-cms-agents-addons-body" do
          fill_in_ckeditor "item[html]", with: html
          click_button I18n.t("cms.link_check")
          wait_for_ajax

          expect(page).to have_css('#errorLinkChecker li', text: "#{success} #{redirection_url5}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failure} #{redirection_self_url}")
        end
      end
    end
  end
end
