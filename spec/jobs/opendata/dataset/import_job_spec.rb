require 'spec_helper'

describe Opendata::Dataset::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create(:opendata_node_dataset, name: "import") }
  let!(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/opendata/dataset_import.zip") }

  describe ".perform_later" do
    before do
      perform_enqueued_jobs do
        described_class.bind(site_id: site).perform_later(ss_file.id)
      end
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(include("INFO -- : Started Job"))
      expect(log.logs).to include(include("INFO -- : Completed Job"))

      pages = Opendata::Dataset.all
      expect(pages.map(&:name)).to eq %w(サンプルデータ【1】)
    end
  end
end
