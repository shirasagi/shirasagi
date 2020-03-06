require 'spec_helper'

describe Opendata::DatasetAccessReportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let!(:node) { create(:opendata_node_dataset, cur_site: site) }
  let!(:node_search) { create(:opendata_node_search_dataset, cur_site: site) }
  let!(:dataset1) { create(:opendata_dataset, cur_site: site, cur_node: node) }
  let!(:dataset2) { create(:opendata_dataset, cur_site: site, cur_node: node) }

  before do
    Timecop.freeze("2019/11/01 00:00:00") do
      create(
        :recommend_history_log, cur_site: site,
        target_id: dataset1.id, target_class: dataset1.class.name, path: dataset1.path, access_url: dataset1.full_url
      )
    end
    Timecop.freeze("2019/11/08 09:00:00") do
      path = "/#{unique_id}.html"
      url = "http://example.jp#{path}"

      # with non-existing dataset
      create(
        :recommend_history_log, cur_site: site,
        target_id: 999_999, target_class: dataset1.class.name, path: path, access_url: url
      )
    end
    Timecop.freeze(Time.zone.parse("2019/11/30 00:00:00").end_of_day) do
      create(
        :recommend_history_log, cur_site: site,
        target_id: dataset1.id, target_class: dataset1.class.name, path: dataset1.path, access_url: dataset1.full_url
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

      expect(Opendata::DatasetAccessReport.all.count).to eq 2
      Opendata::DatasetAccessReport.all.where(dataset_id: dataset1.id).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset1.id
        expect(report.dataset_name).to eq dataset1.name
        expect(report.dataset_url).to eq dataset1.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to be_nil
        expect(report.resource_name).to be_nil
        expect(report.resource_filename).to be_nil
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
      Opendata::DatasetAccessReport.all.where(dataset_id: 999_999).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq 999_999
        expect(report.dataset_name).to eq I18n.t("ss.options.state.deleted")
        expect(report.day7_count).to eq 1
      end
    end
  end

  context "daily normal operation mode" do
    let!(:report1) do
      create(
        :opendata_dataset_access_report, cur_site: site, year_month: 2019 * 100 + 11, dataset_id: rand(100..200)
      )
    end
    let!(:report2) do
      create(
        :opendata_dataset_access_report, cur_site: site, year_month: 2019 * 100 + 10, dataset_id: report1.dataset_id
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

      expect(Opendata::DatasetAccessReport.all.count).to eq 4
      expect(Opendata::DatasetAccessReport.all.where(dataset_id: dataset1.id).count).to eq 1
      expect(Opendata::DatasetAccessReport.all.where(dataset_id: dataset2.id).count).to eq 1
      Opendata::DatasetAccessReport.all.where(dataset_id: dataset1.id).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset1.id
        expect(report.dataset_name).to eq dataset1.name
        expect(report.dataset_url).to eq dataset1.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to be_nil
        expect(report.resource_name).to be_nil
        expect(report.resource_filename).to be_nil
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
      Opendata::DatasetAccessReport.all.where(dataset_id: dataset2.id).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset2.id
        expect(report.dataset_name).to eq dataset2.name
        expect(report.dataset_url).to eq dataset2.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to be_nil
        expect(report.resource_name).to be_nil
        expect(report.resource_filename).to be_nil
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

      Timecop.travel("2019/11/09") do
        described_class.bind(site_id: site.id, node_id: node.id, user_id: user.id).perform_now
      end

      expect(Opendata::DatasetAccessReport.all.count).to eq 5
      Opendata::DatasetAccessReport.all.where(dataset_id: 999_999).first.tap do |report|
        expect(report.deleted).to be_present
        expect(report.dataset_name).to eq I18n.t("ss.options.state.deleted")
        expect(report.day7_count).to eq 1
      end

      Timecop.travel("2019/12/01") do
        described_class.bind(site_id: site.id, node_id: node.id, user_id: user.id).perform_now
      end

      expect(Opendata::DatasetAccessReport.all.count).to eq 5
      Opendata::DatasetAccessReport.all.where(dataset_id: dataset1.id).first.tap do |report|
        expect(report.year_month).to eq 2_019 * 100 + 11
        expect(report.deleted).to be_blank
        expect(report.dataset_id).to eq dataset1.id
        expect(report.dataset_name).to eq dataset1.name
        expect(report.dataset_url).to eq dataset1.full_url
        expect(report.dataset_areas).to be_blank
        expect(report.dataset_categories).to be_blank
        expect(report.dataset_estat_categories).to be_blank
        expect(report.resource_id).to be_nil
        expect(report.resource_name).to be_nil
        expect(report.resource_filename).to be_nil
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
