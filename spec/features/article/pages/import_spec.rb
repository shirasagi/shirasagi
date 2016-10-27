require 'spec_helper'
require "csv"

describe "article_pages", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:index_path) { article_pages_path site.id, node }
  let(:import_path) { import_article_pages_path site.id, node }

  feature "#import_csv" do
    background do
      login_cms_user

      create :cms_node, cur_site: site, name: "くらしのガイド"
      create :cms_layout, cur_site: site, name: "記事レイアウト"
      group = SS::Group.where(name: "シラサギ市/企画政策部/政策課").first
      group ||= create :cms_group, name: "シラサギ市/企画政策部/政策課"
      site.add_to_set(group_ids: [group.id])

      create :article_page, cur_site: site, cur_node: node
      create :article_page, cur_site: site, cur_node: node
    end

    scenario "exec import process" do
      visit index_path
      expect(status_code).to eq(200).or eq(304)

      click_on I18n.t("views.links.import")
      expect(status_code).to eq(200)
      expect(current_path).to eq import_path

      attach_file "item[file]", "spec/fixtures/article/article_import_test_1.csv"
      click_on I18n.t("views.links.import")
      expect(status_code).to eq(200)
      #expect(page).to have_content I18n.t("views.notice.saved")
    end

    #scenario "check import data" do
    #  visit index_path
    #  click_on I18n.t("views.links.import")
    #  expect(current_path).to eq import_path
    #
    #  attach_file "item_in_file", "spec/fixtures/article/article_import_test_1.csv"
    #  click_on I18n.t("views.links.import")
    #  expect(status_code).to eq(200)
    #
    #  click_link 'test_1_title'
    #  expect(status_code).to eq(200)
    #
    #  expect(page).to have_content 'test_1_title'
    #  expect(page).to have_content 'docs/test_1.html'
    #  expect(page).to have_content '記事レイアウト'
    #  expect(page).to have_content 'test_1_keyword'
    #  expect(page).to have_content 'test_1_overview'
    #  expect(page).to have_content 'test_1_summary'
    #  expect(page).to have_content 'test_1_parent_crumb_urls'
    #  expect(page).to have_content 'test_1_event_title'
    #  expect(page).to have_content 'シラサギ市/企画政策部/政策課'
    #  expect(page).to have_content 'test_1_contact_charge'
    #  expect(page).to have_content 'test_1_contact_tel'
    #  expect(page).to have_content 'test_1_contact_fax'
    #  expect(page).to have_content 'test_1_contact_mail'
    #end

    #scenario "fail import process" do
    #  visit index_path
    #  expect(status_code).to eq(200).or eq(304)
    #
    #  click_on I18n.t("views.links.import")
    #  expect(status_code).to eq(200)
    #  expect(current_path).to eq import_path
    #
    #  attach_file "item_in_file", "spec/fixtures/article/article_import_test_2.csv"
    #  click_on I18n.t("views.links.import")
    #  expect(status_code).to eq(200)
    #  expect(current_path).to eq import_path
    #  expect(page).to have_content I18n.t("views.notice.saved")
    #  expect(page).to have_content I18n.t('errors.messages.invalid')
    #
    #  visit index_path
    #  expect(page).to have_content 'test_1_title'
    #  expect(page).to have_content 'test_2_title'
    #  expect(page).to_not have_content 'test_3_title'
    #end
  end
end
