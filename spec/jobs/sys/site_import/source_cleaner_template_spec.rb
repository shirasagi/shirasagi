require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:source_template) { create :cms_source_cleaner_template, site: source_site }
  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = ::Sys::SiteExportJob.new
      job.task = ::Tasks::Cms.mock_task(source_site_id: source_site.id)
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
      job = ::Sys::SiteImportJob.new
      job.task = ::Tasks::Cms.mock_task(target_site_id: destination_site.id, import_file: file_path)
      job.perform

      expect(Cms::SourceCleanerTemplate.site(destination_site).count).to eq 1
      dest_template = Cms::SourceCleanerTemplate.site(destination_site).first
      expect(dest_template.name).to eq source_template.name
      expect(dest_template.order).to eq source_template.order
      expect(dest_template.state).to eq source_template.state
      expect(dest_template.target_type).to eq source_template.target_type
      expect(dest_template.target_value).to eq source_template.target_value
      expect(dest_template.action_type).to eq source_template.action_type
      expect(dest_template.replaced_value).to eq source_template.replaced_value
    end
  end
end
