require 'spec_helper'

describe Faq::Page::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create(:cms_layout, name: "FAQ") }

  let!(:category_1) { create(:category_node_node, filename: "faq", name: "よくある質問") }
  let!(:category_2) { create(:category_node_page, filename: "faq/c1", name: "くらし・手続き") }
  let!(:category_3) { create(:category_node_page, filename: "faq/c2", name: "子育て・教育") }
  let!(:node) { create(:faq_node_page, site: site, filename: "faq/docs", st_category_ids: [category_1.id, category_2.id, category_3.id]) }
  let!(:related_page) { create(:article_page, filename: "docs/page27.html", name: "関連ページ") }

  let!(:file_path) { "#{::Rails.root}/spec/fixtures/faq/import_job/faq_pages.csv" }
  let!(:in_file) { Fs::UploadedFile.create_from_file(file_path) }
  let!(:ss_file) { create(:ss_file, site: site, in_file: in_file ) }

  describe ".perform_later" do
    context "with site" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node).perform_later(ss_file.id)
        end
      end

      it do
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))

        items = Faq::Page.site(site).where(filename: /^#{node.filename}\//, depth: 3)
        expect(items.count).to be 3
      end
    end
  end
end
