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

  let(:success) { I18n.t("errors.messages.link_check_success") }
  let(:failure) { I18n.t("errors.messages.link_check_failure") }

  let(:edit_path) { edit_article_page_path site.id, node, item }

  before do
    stub_request(:get, success_url3).to_return(body: "", status: 200, headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, failed_url3).to_return(body: "", status: 404, headers: { 'Content-Type' => 'text/html' })

    Capybara.app_host = "http://#{site.domain}"

    login_cms_user
  end

  context "check links" do
    context "with cms addon body" do
      let(:item) { create :article_page, cur_node: node, file_ids: [ss_file1.id, ss_file2.id], state: "public" }

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

          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url1} 成功")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url2} 成功")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url3} 成功")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url1} 失敗")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url2} 失敗")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url3} 失敗")
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

          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url1} 成功")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url2} 成功")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url3} 成功")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url1} 失敗")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url2} 失敗")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url3} 失敗")
        end
      end
    end

    context "with entry form" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [ss_file1.id, ss_file2.id], form_id: form.id }

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

          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url1} #{success}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url2} #{success}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url3} #{success}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url1} #{failure}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url2} #{failure}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url3} #{failure}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{invalid_url1} #{failure}")
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

          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url1} #{success}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url2} #{success}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{success_url3} #{success}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url1} #{failure}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url2} #{failure}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{failed_url3} #{failure}")
          expect(page).to have_css('#errorLinkChecker li', text: "#{invalid_url1} #{failure}")
        end
      end
    end
  end
end
