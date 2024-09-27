require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:source_template) do
    file = tmp_ss_file site: source_site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
    create :cms_editor_template, cur_site: source_site, thumb_id: file.id
  end
  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = ::Sys::SiteExportJob.new
      job.task = ::Tasks::Cms.mock_task(source_site_id: source_site.id)
      job.perform
      output_zip = job.instance_variable_get(:@output_zip)

      # site.destroy
      # file.destroy
      # template.destroy

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

      expect(Cms::EditorTemplate.site(destination_site).count).to eq 1
      dest_template = Cms::EditorTemplate.site(destination_site).first
      expect(dest_template.name).to eq source_template.name
      expect(dest_template.description).to eq source_template.description
      expect(dest_template.html).to eq source_template.html
      expect(dest_template.thumb_id).not_to be_nil
      expect(dest_template.thumb_id).not_to eq source_template.thumb_id
      expect(dest_template.thumb.site_id).to eq destination_site.id
      expect(dest_template.thumb.owner_item_id).to eq dest_template.id
      expect(dest_template.thumb.owner_item_type).to eq dest_template.class.name
      expect(::File.size(dest_template.thumb.path)).to be > 0
    end
  end
end
