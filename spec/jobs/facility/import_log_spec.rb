require 'spec_helper'

describe Facility::ImportJob, dbscope: :example do
  let(:model) { Facility::Node::Page }
  let!(:site) { create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"], group_ids: [group1.id]) }
  let!(:layout) { create(:cms_layout, site: site, name: "施設レイアウト") }

  let!(:node_categories) { create(:cms_node_node, site: site, filename: "facilities/categories") }
  let!(:node_category1) { create(:facility_node_category, site: site, filename: "facilities/categories/c1", name: "食べる") }
  let!(:node_category2) { create(:facility_node_category, site: site, filename: "facilities/categories/c2", name: "買う") }
  let!(:node_category3) { create(:facility_node_category, site: site, filename: "facilities/categories/c3", name: "見る・遊ぶ") }

  let!(:node_locations) { create(:cms_node_node, site: site, filename: "facilities/locations") }
  let!(:node_location1) { create(:facility_node_location, site: site, filename: "facilities/locations/l1", name: "シラサギ市") }
  let!(:node_location2) { create(:facility_node_location, site: site, filename: "facilities/locations/l2", name: "すだち市") }
  let!(:node_location3) { create(:facility_node_location, site: site, filename: "facilities/locations/l3", name: "子育て町") }

  let!(:node_services) { create(:cms_node_node, site: site, filename: "facilities/services") }
  let!(:node_service1) { create(:facility_node_service, site: site, filename: "facilities/services/s1", name: "駐車場有") }
  let!(:node_service2) { create(:facility_node_service, site: site, filename: "facilities/services/s2", name: "緊急避難所") }
  let!(:node_service3) { create(:facility_node_service, site: site, filename: "facilities/services/s3", name: "WIFIスポット") }

  let!(:group1) { create(:cms_group, name: "地図管理係") }
  let!(:group2) { create(:cms_group, name: "観光整備係") }
  let!(:group3) { create(:cms_group, name: "特産物係") }

  let!(:node) do
    create(
      :facility_node_page,
      site: site,
      filename: "facilities",
      st_category_ids: [node_category1.id, node_category2.id, node_category3.id],
      st_location_ids: [node_location1.id, node_location2.id, node_location3.id],
      st_service_ids: [node_service1.id, node_service2.id, node_service3.id],
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

  let!(:facility_for_updates1) do
    model.create(
      site_id: 1,
      group_ids: [3],
      name: "シラサギランド",
      filename: "facilities/item_update1",
      layout_id: 1,
      category_ids: [2, 3, 4],
      service_ids: [10, 11, 12],
      location_ids: [6, 7, 8],
      route: "facility/page",
      postcode: "〒111-1234",
      address: "徳島市シラサギ町",
      tel: "0537-292-5977")
  end

  let!(:facility_for_updates2) do
    model.create(
      site_id: 1,
      group_ids: [3],
      name: "シラサギスタジオ",
      filename: "facilities/item_update2",
      layout_id: 1,
      category_ids: [2, 3, 4],
      service_ids: [10, 11, 12],
      location_ids: [6, 7, 8],
      route: "facility/page",
      postcode: "〒123-4321",
      address: "徳島市ヒクイドリ町",
      tel: "0537-292-5977")
  end

  describe ".perform_later" do
    context "create Facility::Node::Page" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site.id, node_id: node.id).perform_later(ss_file1.id)
        end
      end

      it do
        expect(model.all.count).to eq 13
        Job::Log.first do |log|
          expect(log.logs).to_not include(/error/)
          expect(log.logs).to_not include(/update/)
          expect(log.logs).to include(/発生したエラー数は『0件』です。/)
        end
      end
    end

    context "update Facility::Node::Page" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site.id, node_id: node.id).perform_later(ss_file2.id)
        end
      end

      it do
        expect(model.all.count).to eq 3
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/updating 2行目 施設名： シラサギランド to シラサギ施設1/)
          expect(log.logs).to include(/updating 2行目 施設の種類： \["食べる", "買う", "見る・遊ぶ"\] to \["買う"\]/)
          expect(log.logs).to include(/updating 2行目 施設の地域： \["シラサギ市", "すだち市", "子育て町"\] to \["シラサギ市"\]/)
          expect(log.logs).to include(/updating 2行目 施設の用途： \["駐車場有", "緊急避難所", "WIFIスポット"\] to \["駐車場有", "緊急避難所"\]/)
          expect(log.logs).to include(/updating 3行目 郵便番号： 〒123-4321 to 〒222-4321/)
          expect(log.logs).to include(/updating 3行目 施設の種類： \["食べる", "買う", "見る・遊ぶ"\] to \["食べる", "買う"\]/)
          expect(log.logs).to include(/updating 3行目 管理グループ： \["観光整備係"\] to \["地図管理係"\]/)
        end
      end
    end

    context "failed to save Facility::Node::Page" do
      before do
        perform_enqueued_jobs do
          described_class.bind(site_id: site.id, node_id: node.id).perform_later(ss_file3.id)
        end
      end

      it do
        expect(model.all.count).to eq 11
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/error 2行目 施設の種類『走る』が存在しないので登録できませんでした。新規に『走る』を作成した上で、インポートを実行してください。/)
          expect(log.logs).to include(/created page 2行目 施設「シラサギ施設1」が作成されました/)
          expect(log.logs).to include(/error 3行目 管理グループ『掃除係』が存在しないので登録できませんでした。新規に『掃除係』を作成した上で、インポートを実行してください。/)
          expect(log.logs).to include(/created page 3行目 施設「シラサギ施設2」が作成されました。/)
          expect(log.logs).to include(/created page 4行目 施設「シラサギ施設3」が作成されました。/)
          expect(log.logs).to include(/failed 5行目 施設「」の作成・更新がされませんでした。施設名を入力してください/)
          expect(log.logs).to include(/created page 6行目 施設「シラサギ施設5」が作成されました。/)
          expect(log.logs).to include(/failed 7行目 施設「シラサギ施設6」の作成・更新がされませんでした。フォルダー名は不正な値です。/)
          expect(log.logs).to include(/created page 8行目 施設「シラサギ施設7」が作成されました。/)
          expect(log.logs).to include(/created page 9行目 施設「シラサギ施設8」が作成されました。/)
          expect(log.logs).to include(/created page 10行目 施設「シラサギ施設9」が作成されました。/)
          expect(log.logs).to include(/error 11行目 施設の地域『子規町』が存在しないのでを登録できませんでした。新規に『子規町』を作成した上で、インポートを実行してください。/)
          expect(log.logs).to include(/error 11行目 施設の用途『充電スポット』が存在しないので登録できませんでした。新規に『充電スポット』を作成した上で、インポートを実行してください。/)
          expect(log.logs).to include(/created page 11行目 施設「シラサギ施設10」が作成されました。/)
        end
      end
    end
  end
end
