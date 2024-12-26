require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:source_lang) { create :translate_lang_ja, site: source_site }
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
      
      expect(Translate::Lang.site(destination_site).count).to eq 1
      dest_translate_lang = Translate::Lang.site(destination_site).first
      expect(dest_translate_lang.name).to eq source_lang.name
      expect(dest_translate_lang.code).to eq source_lang.code
      expect(dest_translate_lang.mock_code).to eq source_lang.mock_code
      expect(dest_translate_lang.google_translation_code).to eq source_lang.google_translation_code
      expect(dest_translate_lang.microsoft_translator_text_code).to eq source_lang.microsoft_translator_text_code
      expect(dest_translate_lang.accept_languages).to eq source_lang.accept_languages
    end
  end
end
