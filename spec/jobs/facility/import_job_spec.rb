require 'spec_helper'

describe Facility::ImportJob, dbscope: :example do
  let!(:sub_site_1) do
    create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"], group_ids: [group.id])
  end
  let!(:sub_site_2) do
    create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"], group_ids: [group.id])
  end
  let!(:sub_site_3) do
    create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"], group_ids: [group.id])
  end
  let!(:site) { create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"], group_ids: [group.id]) }
  let!(:layout) { create(:cms_layout, name: "施設レイアウト") }
  let!(:group) { create(:cms_group, name: "地図管理係") }

  let!(:node_categories) { create(:cms_node_node, site: site, filename: "facilities/categories") }
  let!(:node_category_1) { create(:facility_node_category, site: site, filename: "facilities/categories/c1", name: "食べる") }
  let!(:node_category_2) { create(:facility_node_category, site: site, filename: "facilities/categories/c2", name: "買う") }
  let!(:node_category_3) { create(:facility_node_category, site: site, filename: "facilities/categories/c3", name: "見る・遊ぶ") }

  let!(:node_locations) { create(:cms_node_node, site: site, filename: "facilities/locations") }
  let!(:node_location_1) { create(:facility_node_location, site: site, filename: "facilities/locations/l1", name: "シラサギ市") }
  let!(:node_location_2) { create(:facility_node_location, site: site, filename: "facilities/locations/l2", name: "すだち市") }
  let!(:node_location_3) { create(:facility_node_location, site: site, filename: "facilities/locations/l3", name: "子育て町") }

  let!(:node_services) { create(:cms_node_node, site: site, filename: "facilities/services") }
  let!(:node_service_1) { create(:facility_node_service, site: site, filename: "facilities/services/s1", name: "駐車場有") }
  let!(:node_service_2) { create(:facility_node_service, site: site, filename: "facilities/services/s2", name: "緊急避難所") }
  let!(:node_service_3) { create(:facility_node_service, site: site, filename: "facilities/services/s3", name: "WIFIスポット") }

  let!(:node) do
    create(
      :facility_node_page,
      site: site,
      filename: "facilities",
      st_category_ids: [node_category_1.id, node_category_2.id, node_category_3.id],
      st_location_ids: [node_location_1.id, node_location_2.id, node_location_3.id],
      st_service_ids: [node_service_1.id, node_service_2.id, node_service_3.id])
  end

  let!(:file_path) { "#{::Rails.root}/spec/fixtures/facility/import_job/facility_node_pages.csv" }
  let!(:in_file) { Fs::UploadedFile.create_from_file(file_path) }
  let!(:ss_file) { create(:ss_file, site: site, in_file: in_file ) }
  let!(:expected_table) do
    table = CSV.read( "#{::Rails.root}/spec/fixtures/facility/import_job/facility_node_pages.csv", encoding: 'SJIS:UTF-8')
    table.map { |row| row.map{ |v| v ? v.split("\n") : v }.flatten.compact }
  end

  describe ".perform_later" do
    context "with site" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node).perform_later(ss_file.id)
        end
      end

      it do
        log = Job::Log.first
        expect(log.log).to include("INFO -- : Started Job")
        expect(log.log).to include("INFO -- : Completed Job")

        csv = Facility::Node::Page.site(site).where(filename: /^#{node.filename}\//, depth: 2).to_csv
        table = CSV.parse(csv).map { |row| row.map{ |v| v ? v.split("\n") : v }.flatten.compact }
        table.each_with_index do |row, idx|
          expect(row).to match_array expected_table[idx]
        end
      end
    end
  end
end
