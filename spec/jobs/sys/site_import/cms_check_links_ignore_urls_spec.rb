require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:item1) { create :check_links_ignore_url, site: source_site }
  let!(:item2) { create :check_links_ignore_url, site: source_site }

  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = ::Sys::SiteExportJob.new
      job.bind("site_id" => source_site.id).perform
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
      job.bind("site_id" => destination_site.id).perform(file_path)

      expect(Cms::CheckLinks::IgnoreUrl.site(destination_site).count).to eq 2
      dest_item1 = Cms::CheckLinks::IgnoreUrl.site(destination_site).where(name: item1.name).first
      dest_item2 = Cms::CheckLinks::IgnoreUrl.site(destination_site).where(name: item2.name).first
      expect(dest_item1).to be_present
      expect(dest_item2).to be_present
    end
  end
end
