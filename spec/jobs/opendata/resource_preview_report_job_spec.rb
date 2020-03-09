require 'spec_helper'

describe Opendata::ResourcePreviewReportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let!(:node) { create(:opendata_node_dataset, cur_site: site) }
  let!(:node_search) { create(:opendata_node_search_dataset, cur_site: site) }

  let!(:dataset1) { create(:opendata_dataset, cur_site: site, cur_node: node) }
  let(:resource_file_path) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let!(:license) { create(:opendata_license, cur_site: site) }

  let!(:dataset2_with_no_resources) { create(:opendata_dataset, cur_site: site, cur_node: node) }
  let!(:dataset3) { create(:opendata_dataset, cur_site: site, cur_node: node) }

  before do
    resource = Fs::UploadedFile.create_from_file(resource_file_path, basename: "spec") do |f|
      dataset1.resources.create(
        name: unique_id, in_file: f, license_id: license.id, filename: ::File.basename(resource_file_path), format: "CSV"
      )
    end

    remote_addr = "10.0.0.1"
    user_agent = "user-agent-#{unique_id}"
    resource.create_preview_history(remote_addr, user_agent, Time.zone.parse("2019/11/01 00:00:00"))
    resource.create_preview_history(remote_addr, user_agent, Time.zone.parse("2019/11/30 00:00:00").end_of_day)

    Fs::UploadedFile.create_from_file(resource_file_path, basename: "spec") do |f|
      dataset3.resources.create(
        name: unique_id, in_file: f, license_id: license.id, filename: ::File.basename(resource_file_path), format: "CSV"
      )
    end
  end

  context "batch recovery mode" do
    it do
      described_class.bind(site_id: site.id, node_id: node.id, user_id: user.id).perform_now("2019/11/01", "2019/11/30")

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      expect(Opendata::ResourcePreviewReport.all.count).to eq 1
      Opendata::ResourcePreviewReport.all.first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset1.id
        expect(report.dataset_name).to eq dataset1.name
        expect(report.dataset_url).to eq dataset1.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to eq dataset1.resources.first.id
        expect(report.resource_name).to eq dataset1.resources.first.name
        expect(report.resource_filename).to eq dataset1.resources.first.filename
        expect(report.day0_count).to eq 1
        expect(report.day1_count).to be_blank
        expect(report.day2_count).to be_blank
        expect(report.day3_count).to be_blank
        expect(report.day4_count).to be_blank
        expect(report.day5_count).to be_blank
        expect(report.day6_count).to be_blank
        expect(report.day7_count).to be_blank
        expect(report.day8_count).to be_blank
        expect(report.day9_count).to be_blank
        expect(report.day10_count).to be_blank
        expect(report.day11_count).to be_blank
        expect(report.day12_count).to be_blank
        expect(report.day13_count).to be_blank
        expect(report.day14_count).to be_blank
        expect(report.day15_count).to be_blank
        expect(report.day16_count).to be_blank
        expect(report.day17_count).to be_blank
        expect(report.day18_count).to be_blank
        expect(report.day19_count).to be_blank
        expect(report.day20_count).to be_blank
        expect(report.day21_count).to be_blank
        expect(report.day22_count).to be_blank
        expect(report.day23_count).to be_blank
        expect(report.day24_count).to be_blank
        expect(report.day25_count).to be_blank
        expect(report.day26_count).to be_blank
        expect(report.day27_count).to be_blank
        expect(report.day28_count).to be_blank
        expect(report.day29_count).to eq 1
        expect(report.day30_count).to be_blank
      end
    end
  end

  context "daily normal operation mode" do
    let!(:report1) do
      create(
        :opendata_resource_preview_report, cur_site: site, year_month: 2019 * 100 + 11,
        dataset_id: rand(100..200), resource_id: rand(200..300)
      )
    end
    let!(:report2) do
      create(
        :opendata_resource_preview_report, cur_site: site, year_month: 2019 * 100 + 10,
        dataset_id: report1.dataset_id, resource_id: report1.resource_id
      )
    end

    it do
      Timecop.travel("2019/11/02") do
        described_class.bind(site_id: site.id, node_id: node.id, user_id: user.id).perform_now
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      expect(Opendata::ResourcePreviewReport.all.count).to eq 4
      expect(Opendata::ResourcePreviewReport.all.where(dataset_id: dataset1.id).count).to eq 1
      expect(Opendata::ResourcePreviewReport.all.where(dataset_id: dataset3.id).count).to eq 1
      Opendata::ResourcePreviewReport.all.where(dataset_id: dataset1.id).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset1.id
        expect(report.dataset_name).to eq dataset1.name
        expect(report.dataset_url).to eq dataset1.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to eq dataset1.resources.first.id
        expect(report.resource_name).to eq dataset1.resources.first.name
        expect(report.resource_filename).to eq dataset1.resources.first.filename
        expect(report.day0_count).to eq 1
        expect(report.day1_count).to be_blank
        expect(report.day2_count).to be_blank
        expect(report.day3_count).to be_blank
        expect(report.day4_count).to be_blank
        expect(report.day5_count).to be_blank
        expect(report.day6_count).to be_blank
        expect(report.day7_count).to be_blank
        expect(report.day8_count).to be_blank
        expect(report.day9_count).to be_blank
        expect(report.day10_count).to be_blank
        expect(report.day11_count).to be_blank
        expect(report.day12_count).to be_blank
        expect(report.day13_count).to be_blank
        expect(report.day14_count).to be_blank
        expect(report.day15_count).to be_blank
        expect(report.day16_count).to be_blank
        expect(report.day17_count).to be_blank
        expect(report.day18_count).to be_blank
        expect(report.day19_count).to be_blank
        expect(report.day20_count).to be_blank
        expect(report.day21_count).to be_blank
        expect(report.day22_count).to be_blank
        expect(report.day23_count).to be_blank
        expect(report.day24_count).to be_blank
        expect(report.day25_count).to be_blank
        expect(report.day26_count).to be_blank
        expect(report.day27_count).to be_blank
        expect(report.day28_count).to be_blank
        expect(report.day29_count).to be_blank
        expect(report.day30_count).to be_blank
      end
      Opendata::ResourcePreviewReport.all.where(dataset_id: dataset3.id).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset3.id
        expect(report.dataset_name).to eq dataset3.name
        expect(report.dataset_url).to eq dataset3.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to eq dataset3.resources.first.id
        expect(report.resource_name).to eq dataset3.resources.first.name
        expect(report.resource_filename).to eq dataset3.resources.first.filename
        expect(report.day0_count).to be_blank
        expect(report.day1_count).to be_blank
        expect(report.day2_count).to be_blank
        expect(report.day3_count).to be_blank
        expect(report.day4_count).to be_blank
        expect(report.day5_count).to be_blank
        expect(report.day6_count).to be_blank
        expect(report.day7_count).to be_blank
        expect(report.day8_count).to be_blank
        expect(report.day9_count).to be_blank
        expect(report.day10_count).to be_blank
        expect(report.day11_count).to be_blank
        expect(report.day12_count).to be_blank
        expect(report.day13_count).to be_blank
        expect(report.day14_count).to be_blank
        expect(report.day15_count).to be_blank
        expect(report.day16_count).to be_blank
        expect(report.day17_count).to be_blank
        expect(report.day18_count).to be_blank
        expect(report.day19_count).to be_blank
        expect(report.day20_count).to be_blank
        expect(report.day21_count).to be_blank
        expect(report.day22_count).to be_blank
        expect(report.day23_count).to be_blank
        expect(report.day24_count).to be_blank
        expect(report.day25_count).to be_blank
        expect(report.day26_count).to be_blank
        expect(report.day27_count).to be_blank
        expect(report.day28_count).to be_blank
        expect(report.day29_count).to be_blank
        expect(report.day30_count).to be_blank
      end

      expect(report1.deleted).to be_blank
      report1.reload
      expect(report1.deleted).to be_present

      expect(report2.deleted).to be_blank
      report2.reload
      expect(report2.deleted).to be_present

      Timecop.travel("2019/12/01") do
        described_class.bind(site_id: site.id, node_id: node.id, user_id: user.id).perform_now
      end

      expect(Opendata::ResourcePreviewReport.all.count).to eq 4
      Opendata::ResourcePreviewReport.all.where(dataset_id: dataset1.id).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset1.id
        expect(report.dataset_name).to eq dataset1.name
        expect(report.dataset_url).to eq dataset1.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to eq dataset1.resources.first.id
        expect(report.resource_name).to eq dataset1.resources.first.name
        expect(report.resource_filename).to eq dataset1.resources.first.filename
        expect(report.day0_count).to eq 1
        expect(report.day1_count).to be_blank
        expect(report.day2_count).to be_blank
        expect(report.day3_count).to be_blank
        expect(report.day4_count).to be_blank
        expect(report.day5_count).to be_blank
        expect(report.day6_count).to be_blank
        expect(report.day7_count).to be_blank
        expect(report.day8_count).to be_blank
        expect(report.day9_count).to be_blank
        expect(report.day10_count).to be_blank
        expect(report.day11_count).to be_blank
        expect(report.day12_count).to be_blank
        expect(report.day13_count).to be_blank
        expect(report.day14_count).to be_blank
        expect(report.day15_count).to be_blank
        expect(report.day16_count).to be_blank
        expect(report.day17_count).to be_blank
        expect(report.day18_count).to be_blank
        expect(report.day19_count).to be_blank
        expect(report.day20_count).to be_blank
        expect(report.day21_count).to be_blank
        expect(report.day22_count).to be_blank
        expect(report.day23_count).to be_blank
        expect(report.day24_count).to be_blank
        expect(report.day25_count).to be_blank
        expect(report.day26_count).to be_blank
        expect(report.day27_count).to be_blank
        expect(report.day28_count).to be_blank
        expect(report.day29_count).to eq 1
        expect(report.day30_count).to be_blank
      end
    end
  end
end
