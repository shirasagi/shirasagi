require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }

  let!(:node) { create(:event_node_page, cur_site: source_site) }
  let!(:today) { Time.zone.today }
  let!(:event_recur1) do
    { kind: "date", start_at: today, frequency: "daily", until_on: today }
  end
  let!(:event_recur2) do
    {
      kind: "datetime",
      start_at: today.in_time_zone.change(hour: 12),
      end_at: today.in_time_zone.change(hour: 13),
      frequency: "daily",
      until_on: today
    }
  end
  let!(:event_recur3) do
    {
      kind: "datetime",
      start_at: today.in_time_zone.change(hour: 14),
      end_at: today.in_time_zone.change(hour: 15),
      frequency: "daily",
      until_on: today
    }
  end
  let!(:item1) { create :event_page, cur_site: source_site, cur_node: node, event_recurrences: [event_recur1] }
  let!(:item2) { create :event_page, cur_site: source_site, cur_node: node, event_recurrences: [event_recur2] }
  let!(:item3) { create :event_page, cur_site: source_site, cur_node: node, event_recurrences: [event_recur3] }

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

      destination_node = node.class.site(destination_site).where(filename: node.filename).first
      destination_item1 = item1.class.site(destination_site).where(filename: item1.filename).first
      destination_item2 = item2.class.site(destination_site).where(filename: item2.filename).first
      destination_item3 = item3.class.site(destination_site).where(filename: item3.filename).first

      expect(destination_node).to be_present
      expect(destination_item1).to be_present
      expect(destination_item2).to be_present
      expect(destination_item3).to be_present

      expect(destination_item1.event_recurrences.to_json).to eq item1.event_recurrences.to_json
      expect(destination_item2.event_recurrences.to_json).to eq item2.event_recurrences.to_json
      expect(destination_item3.event_recurrences.to_json).to eq item3.event_recurrences.to_json
    end
  end
end
