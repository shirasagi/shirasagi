require 'spec_helper'

describe "michecker", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create(:faq_node_page, filename: "docs", name: "faq") }
  let(:item) { create(:faq_page, cur_node: node) }
  let(:show_path) { faq_page_path site.id, node, item }

  context "route check" do
    before { login_cms_user }

    it do
      visit show_path
      click_on I18n.t('cms.links.michecker')

      switch_to_window(windows.last)
      wait_for_document_loading
      within ".michecker-head" do
        expect(page).to have_content(I18n.t("cms.cms/michecker.prepared"), wait: 60)
        click_on I18n.t('cms.cms/michecker.start')

        expect(page).to have_content(I18n.t("cms.cms/michecker.michecker_started"), wait: 60)
      end

      expect(enqueued_jobs.size).to eq 1
      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Cms::MicheckerJob
        expect(enqueued_job[:args].first).to eq "page"
        expect(enqueued_job[:args].second).to eq item.id.to_s
      end
    end
  end
end
