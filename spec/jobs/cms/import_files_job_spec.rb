require 'spec_helper'

describe Cms::ImportFilesJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:cms_node_import_node, name: "import") }
  let!(:in_file) { Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/cms/import/site.zip", nil, true) }
  let!(:import_job_file) do
    create(:cms_import_job_file, site: site, node: node, name: "sample", basename: "sample", in_file: in_file)
  end

  describe ".perform_later" do
    before do
      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later
      end
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).not_to include(/INFO -- : .* error:/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      pages = Cms::ImportPage.all
      nodes = Cms::Node::ImportNode.all
      expect(pages.pluck(:name).sort).to eq %w(index.html page.html)
      expect(nodes.pluck(:name).sort).to eq %w(article css img import)

      pages.each do |page|
        expect(page.html.present?).to eq true
        page.html.scan(/(href|src)="\/(.+?)"/) do
          path = $2
          expect(path =~ /#{::Regexp.escape(node.filename)}\//).to eq 0
        end
      end

      expect(Cms::ImportJobFile.count).to eq 0
    end
  end
end
