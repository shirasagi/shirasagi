require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20211011000000_rm_cms_import_files.rb")

RSpec.describe SS::Migration20211011000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create_once :cms_node_import_node, name: "import" }
  let!(:file) { "#{Rails.root}/spec/fixtures/cms/import/site.zip" }

  let!(:job_file) do
    job_file = Cms::ImportJobFile.new(site_id: site.id, node_id: node.id)
    job_file.import_date = 1.day.since

    Fs::UploadedFile.create_from_file(file) do |in_file|
      job_file.in_file = in_file
      job_file.save
    end

    job_file
  end

  context 'job_file exists' do
    it do
      expect(Cms::ImportJobFile.all.size).to eq 1
      expect(SS::File.all.size).to eq 1

      described_class.new.change

      expect(Cms::ImportJobFile.all.size).to eq 1
      expect(SS::File.all.size).to eq 1
    end
  end

  context 'job_file deleted' do
    it do
      job_file.delete

      expect(Cms::ImportJobFile.all.size).to eq 0
      expect(SS::File.all.size).to eq 1

      described_class.new.change

      expect(Cms::ImportJobFile.all.size).to eq 0
      expect(SS::File.all.size).to eq 0
    end
  end
end
