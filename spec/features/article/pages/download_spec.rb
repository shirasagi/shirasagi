require 'spec_helper'
require "csv"

describe "article_pages", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:index_path) { article_pages_path site.id, node }

  feature "#download", js: true do
    background do
      login_cms_user

      create :article_page, cur_site: site, cur_node: node
      create :article_page, cur_site: site, cur_node: node
    end

    scenario "click on download button without check in checkbox" do
      visit index_path
      expect(status_code).to eq 200

      click_on I18n.t("views.links.download")
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page.response_headers['Content-Disposition']).to match(/filename="article_pages_[\d]+\.csv"$/)
    end

    scenario "click on download button to check in checkbox" do
      visit index_path
      expect(status_code).to eq 200

      all(".check")[1].click
      expect(page).to have_checked_field 'ids[]'

      click_on I18n.t("views.links.download")
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page.response_headers['Content-Disposition']).to match(/filename="article_pages_[\d]+\.csv"$/)
    end
  end
end
