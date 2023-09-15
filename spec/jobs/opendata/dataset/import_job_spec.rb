require 'spec_helper'

describe Opendata::Dataset::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :opendata_node_dataset, cur_site: site }
  let!(:node_search) { create :opendata_node_search_dataset, cur_site: site }
  let!(:license) { create(:opendata_license, cur_site: site, uid: "cc-by", name: "表示（CC BY）") }

  describe "#perform" do
    let!(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/opendata/dataset_import.zip") }

    before do
      @save_url_type = SS.config.sns.url_type
      SS.config.replace_value_at(:sns, :url_type, 'any')
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)

      expect do
        described_class.bind(site_id: site, node_id: node).perform_now(ss_file.id)
      end.to output(/サンプルデータ【1】/).to_stdout
    ensure
      SS.config.replace_value_at(:sns, :url_type, @save_url_type)
      Sys::TrustedUrlValidator.send(:clear_trusted_urls)
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(Opendata::Dataset.all.count).to eq 1
      Opendata::Dataset.all.first.tap do |dataset|
        expect(dataset.name).to eq "サンプルデータ【1】"
        expect(dataset.resources.count).to eq 1
        dataset.resources.first.tap do |resource|
          expect(resource.name).to eq "サンプルリソース"
          expect(resource.filename).to eq "sample.txt"
          expect(resource.text).to be_blank
          expect(resource.format).to eq "TXT"
          expect(resource.source_url).to be_blank
          expect(resource.license.id).to eq license.id
          expect(resource.file.name).to eq "sample.txt"
          expect(resource.file.filename).to eq "sample.txt"
          expect(::File.size(resource.file.path)).to be > 0
          expect(resource.file.owner_item_id).to eq dataset.id
          expect(resource.file.owner_item_type).to eq dataset.class.name
        end
      end
    end
  end

  context "zip slip vulnerability" do
    let!(:zip_file) { tmpfile(extname: ".zip") }

    before do
      Zip::File.open(zip_file, Zip::File::CREATE) do |zip|
        zip.get_output_stream("../shift_jis.csv") do |f|
          IO.copy_stream("#{Rails.root}/spec/fixtures/opendata/shift_jis.csv", f)
        end
        # datasets.csv is required
        zip.get_output_stream("datasets.csv") do |f|
          f.puts "hello"
        end
      end

      ss_file = tmp_ss_file(contents: zip_file)
      expect do
        described_class.bind(site_id: site, node_id: node).perform_now(ss_file.id)
      end.to output(/#{::File.basename(zip_file)}/).to_stdout
    end

    it do
      log = Job::Log.first
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(::File.exist?("#{Rails.root}/shift_jis.csv")).to be_falsey
      expect(::File.exist?("#{Rails.root}/tmp/shift_jis.csv")).to be_falsey

      expect(Opendata::Dataset.all.count).to eq 0
    end
  end
end
