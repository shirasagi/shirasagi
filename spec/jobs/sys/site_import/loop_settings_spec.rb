require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:source_setting) { create :cms_loop_setting, site: source_site }
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

      expect(Cms::LoopSetting.site(destination_site).count).to eq 1
      dest_loop_setting = Cms::LoopSetting.site(destination_site).first
      expect(dest_loop_setting.name).to eq source_setting.name
      expect(dest_loop_setting.description).to eq source_setting.description
      expect(dest_loop_setting.order).to eq source_setting.order
      expect(dest_loop_setting.html).to eq source_setting.html
    end
  end
end
