require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:source_dictionary) { create :cms_word_dictionary, site: source_site }
  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = Sys::SiteExportJob.new
      job.task = Tasks::Cms.mock_task(source_site_id: source_site.id)
      job.perform
      output_zip = job.instance_variable_get(:@output_zip)

      output_zip
    ensure
      Sys::SiteExportJob.export_root = save_export_root
    end
  end

  describe "#perform" do
    let!(:destination_site) { create :cms_site_unique }

    it do
      job = Sys::SiteImportJob.new
      job.task = Tasks::Cms.mock_task(target_site_id: destination_site.id, import_file: file_path)
      job.perform

      expect(Cms::WordDictionary.site(destination_site).count).to eq 1
      dest_dictionary = Cms::WordDictionary.site(destination_site).first
      expect(dest_dictionary.name).to eq source_dictionary.name
      expect(dest_dictionary.body).to eq source_dictionary.body
    end
  end
end
