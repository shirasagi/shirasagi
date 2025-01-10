require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:translate_text_cache) do
    Translate::TextCache.create(
      cur_site: source_site, api: SS.config.translate.api_options.to_a.sample[0], update_state: %w(auto manually).sample,
      text: "text-#{unique_id}", original_text: "original_text-#{unique_id}",
      source: "source-#{unique_id}", target: "target-#{unique_id}"
    )
  end
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

      expect(Translate::TextCache.site(destination_site).count).to eq 1
      dest_translate_text_cache = Translate::TextCache.site(destination_site).first
      expect(dest_translate_text_cache.api).to eq translate_text_cache.api
      expect(dest_translate_text_cache.update_state).to eq translate_text_cache.update_state
      expect(dest_translate_text_cache.text).to eq translate_text_cache.text
      expect(dest_translate_text_cache.original_text).to eq translate_text_cache.original_text
      expect(dest_translate_text_cache.source).to eq translate_text_cache.source
      expect(dest_translate_text_cache.target).to eq translate_text_cache.target
    end
  end
end
