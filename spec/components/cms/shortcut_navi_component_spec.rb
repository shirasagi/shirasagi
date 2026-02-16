require 'spec_helper'

describe Cms::ShortCutNaviComponent, type: :component, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site0) { cms_site }
  let!(:user0) { cms_user }
  let!(:group) { create :cms_group, name: unique_id }
  let!(:site) { create :cms_site_unique, group_ids: [ group.id ] }
  let!(:role) do
    permissions = %w(read_private_cms_nodes)
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

  context "without shortcut nodes" do
    it do
      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        html = render_inline component
        expect(html.to_s).to be_blank
      end

      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        # ショートカットが存在しない場合、キャッシュは作成されない
        expect(component.cache_exist?).to be_falsey
      end
    end
  end

  context "with shortcut nodes" do
    let!(:node1) do
      Timecop.freeze(now - 5.days) do
        create(
          :article_node_page, cur_site: site, name: "name-1", shortcuts: [ Cms::Node::SHORTCUT_NAVI ],
          group_ids: [ group.id ])
      end
    end
    let!(:node2_1) do
      Timecop.freeze(now - 4.days) do
        create(
          :category_node_page, cur_site: site, name: "name-2-1", shortcuts: [ Cms::Node::SHORTCUT_NAVI ],
          group_ids: [ group.id ])
      end
    end
    let!(:node2_2) do
      Timecop.freeze(now - 4.days) do
        create(
          :category_node_page, cur_site: site, name: "name-2-2", shortcuts: [ Cms::Node::SHORTCUT_NAVI ],
          group_ids: [])
      end
    end
    let!(:node3) do
      Timecop.freeze(now - 3.days) do
        create(
          :inquiry_node_form, cur_site: site, name: "name-3", shortcuts: [ Cms::Node::SHORTCUT_NAVI ],
          group_ids: [ group.id ])
      end
    end

    it do
      # テスト開始時点ではキャッシュは存在しない
      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".icon-material").tap do |links|
          expect(links).to have(3).items
          expect(links[0].text).to eq node1.name
          expect(links[1].text).to eq node2_1.name
          expect(links[2].text).to eq node3.name
        end

        # 初回描画時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end

      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        # ショートカットが存在する場合、キャッシュされる
        expect(component.cache_exist?).to be_truthy
      end

      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        render_inline component

        # 最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end

      # user1 が閲覧可能なフォルダーを変更する（3つ見えるフォルダーのうちの真ん中を変更する）
      node2_1.without_record_timestamps do
        node2_1.update!(group_ids: [])
      end
      node2_2.without_record_timestamps do
        node2_2.update!(group_ids: [ group.id ])
      end

      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user, cur_node: nil).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".icon-material").tap do |links|
          expect(links).to have(3).items
          expect(links[0].text).to eq node1.name
          expect(links[1].text).to eq node2_2.name
          expect(links[2].text).to eq node3.name
        end

        # 初回描画時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end
    end
  end
end
