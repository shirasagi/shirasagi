require 'spec_helper'

describe Cms::PageSearchNaviComponent, type: :component, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:user0) { cms_user }
  let!(:group) { create :cms_group, name: unique_id }
  let!(:site) { create :cms_site_unique, group_ids: [ group.id ] }
  let!(:role) do
    permissions = %w(read_private_cms_page_searches)
    create :cms_role, cur_site: site, site: site, permissions: permissions
  end
  let!(:user) { create :cms_test_user, group_ids: [ group.id ], cms_role_ids: [ role.id ] }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
    Rails.cache.clear
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  context "without cms/page_search items" do
    it do
      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        html = render_inline component
        expect(html.to_s).to be_blank
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        # 表示すべきものが存在しない場合、キャッシュは作成されない
        expect(component.cache_exist?).to be_falsey
      end
    end
  end

  context "with cms/page_search items" do
    let!(:search1) do
      create(:cms_page_search, cur_site: site, name: "name-1", order: 10, group_ids: [ group.id ])
    end
    let!(:search2_1) do
      create(:cms_page_search, cur_site: site, name: "name-2-1", order: 21, group_ids: [ group.id ])
    end
    let!(:search2_2) do
      create(:cms_page_search, cur_site: site, name: "name-2-2", order: 22, group_ids: [])
    end
    let!(:search3) do
      create(:cms_page_search, cur_site: site, name: "name-3", order: 30, group_ids: [ group.id ])
    end

    it do
      # テスト開始時点ではキャッシュは存在しない
      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".icon-search").tap do |links|
          expect(links).to have(3).items
          expect(links[0].text).to eq search1.name
          expect(links[1].text).to eq search2_1.name
          expect(links[2].text).to eq search3.name
        end

        # 初回描画時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        # 表示すべきものが存在しない場合、キャッシュされる
        expect(component.cache_exist?).to be_truthy
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        render_inline component

        # 最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end

      # user1 が閲覧可能な検索を変更する（3つ見える検索のうちの真ん中を変更する）
      search2_1.without_record_timestamps do
        search2_1.update!(group_ids: [])
      end
      search2_2.without_record_timestamps do
        search2_2.update!(group_ids: [ group.id ])
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".icon-search").tap do |links|
          expect(links).to have(3).items
          expect(links[0].text).to eq search1.name
          expect(links[1].text).to eq search2_2.name
          expect(links[2].text).to eq search3.name
        end

        # 初回描画時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end
    end
  end
end
