require 'spec_helper'

describe Event::Page::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create(:cms_layout, name: "イベント") }
  let!(:node) { create(:event_node_page, site: site, filename: "calendar") }

  let!(:file_path) { "#{::Rails.root}/spec/fixtures/event/import_job/event_pages.csv" }
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

        items = Event::Page.site(site).where(filename: /^#{node.filename}\//, depth: 2)
        expect(items.count).to be 3
      end
    end
  end
end
