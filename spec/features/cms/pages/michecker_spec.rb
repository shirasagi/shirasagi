require 'spec_helper'

describe "michecker", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create(:cms_node, cur_site: site) }
  let(:item) { create(:cms_page, cur_site: site, cur_node: node) }
  let(:show_path) { cms_page_path site.id, node, item }

  context "route check" do
    before { login_cms_user }

    it do
      visit show_path
      new_window = window_opened_by { click_on I18n.t('cms.links.michecker') }
      within_window new_window do
        wait_for_document_loading
        wait_for_js_ready
        within ".michecker-head" do
          expect(page).to have_content(I18n.t("cms.cms/michecker.prepared"), wait: 60)
          click_on I18n.t('cms.cms/michecker.start')

          expect(page).to have_content(I18n.t("cms.cms/michecker.michecker_started"), wait: 60)
        end
      end

      expect(enqueued_jobs.size).to eq 1
      enqueued_jobs.first.tap do |enqueued_job|
        expect(enqueued_job[:job]).to eq Cms::MicheckerJob
        expect(enqueued_job[:args].first).to eq "page"
        expect(enqueued_job[:args].second).to eq item.id.to_s
      end
    end

    context 'with node_page_path' do
      let(:show_path) { node_page_path site.id, node, item }

      it do
        visit show_path
        new_window = window_opened_by { click_on I18n.t('cms.links.michecker') }
        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          within ".michecker-head" do
            expect(page).to have_content(I18n.t("cms.cms/michecker.prepared"), wait: 60)
            click_on I18n.t('cms.cms/michecker.start')

            expect(page).to have_content(I18n.t("cms.cms/michecker.michecker_started"), wait: 60)
          end
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
end
