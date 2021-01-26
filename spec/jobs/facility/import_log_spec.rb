require 'spec_helper'

describe Facility::ImportJob, dbscope: :example do
  let(:model) { Facility::Node::Page }
  let!(:site) { create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"], group_ids: [group1.id]) }
  let!(:layout) { create(:cms_layout, site: site, name: "施設レイアウト") }

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

  let!(:group1) { create(:cms_group, name: "地図管理係") }
  let!(:group2) { create(:cms_group, name: "観光整備係") }
  let!(:group3) { create(:cms_group, name: "特産物係") }

  let!(:facility_node_page) do 
    model.create(
      site_id: 1,
      permission_level: 1,
      group_ids: [3],
      name: "シラサギランド",
      filename: "item1",
      depth: 3,
      category_ids: [177, 179],
      service_ids: [182],
      location_ids: [172, 173],
      route: "facility/page",
      shortcut: "hide",
      keywords: ["施設一覧"],
      postcode: "〒111-1234",
      address: "徳島市シラサギ町",
      tel: "0537-292-5977")
  end

  let!(:node) do
    create(
      :facility_node_page,
      site: site,
      filename: "facilities",
      st_category_ids: [node_category_1.id, node_category_2.id, node_category_3.id],
      st_location_ids: [node_location_1.id, node_location_2.id, node_location_3.id],
      st_service_ids: [node_service_1.id, node_service_2.id, node_service_3.id],
      group_ids: [group1.id, group2.id, group3.id])
  end

  let!(:file_path1) { "#{::Rails.root}/spec/fixtures/facility/import_job/facility_node_pages_add_test.csv" }
  let!(:in_file1) { Fs::UploadedFile.create_from_file(file_path1) }
  let!(:ss_file1) { create(:ss_file, site: site, in_file: in_file1 ) }

  let!(:file_path2) { "#{::Rails.root}/spec/fixtures/facility/import_job/facility_node_pages_update_test.csv" }
  let!(:in_file2) { Fs::UploadedFile.create_from_file(file_path2) }
  let!(:ss_file2) { create(:ss_file, site: site, in_file: in_file2) }

  let!(:file_path3) { "#{::Rails.root}/spec/fixtures/facility/import_job/facility_node_pages_error_test.csv" }
  let!(:in_file3) { Fs::UploadedFile.create_from_file(file_path3) }
  let!(:ss_file3) { create(:ss_file, site: site, in_file: in_file3) }


  describe ".perform_later" do
    context "new record" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node).perform_later(ss_file1.id)
        end
      end

      it "succeed to save all" do
        puts facility_node_page11
        expect(model.all.count).to eq 12
        Job::Log.first do |log|
          expect(log.logs).to_not include(/error/)
          expect(log.logs).to_not include(/update/)
          expect(log.logs).to include(/発生したエラー数は『0件』です。/)
        end
      end
    end

    context "update data and metadata" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node).perform_later(ss_file3.id)
        end
      end

      it do
        puts Facility::Node::Page.first.name
        Job::Log.first.tap do |log|

        end
      end
    end

    context "failed to save data and metadata" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site, node_id: node).perform_later(ss_file2.id)
        end
      end

      it do
        expect(model.all.count).to eq 10
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/error 2行目:  施設の種類『観光する』を登録できませんでした。/)
          expect(log.logs).to include(/error 3行目のデータは登録できませんでした。入力内容をもう１度ご確認ください。/)
          expect(log.logs).to include(/error 3行目: 施設名を入力してください。/)
          expect(log.logs).to include(/error 5行目:  施設の地域『スズメ市』を登録できませんでした。/)
          expect(log.logs).to include(/error 6行目:  施設の用途『充電スポット』を登録できませんでした。/)
          expect(log.logs).to include(/error 8行目:  管理グループ『掃除係』を登録できませんでした。/)
          expect(log.logs).to include(/error 10行目のデータは登録できませんでした。入力内容をもう１度ご確認ください。/)
          expect(log.logs).to include(/error 10行目: フォルダー名は不正な値です。/)
        end
      end
    end
  end
end
