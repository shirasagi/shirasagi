require 'spec_helper'

describe Cms::ShortcutComponent, type: :component, dbscope: :example do
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

  around do |example|
    with_request_url("/.s#{site.id}/cms/contents") do
      with_controller_class(Cms::ContentsController) do
        example.run
      end
    end
  end

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
    Rails.cache.clear
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  context "without nodes" do
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

  context "with shortcut nodes" do
    let!(:node1) do
      Timecop.freeze(now - 5.days) do
        create(
          :article_node_page, cur_site: site, filename: "name-1", shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ],
          group_ids: [ group.id ])
      end
    end
    let!(:node2_1) do
      Timecop.freeze(now - 4.days) do
        create(
          :category_node_page, cur_site: site, filename: "name-2-1", shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ],
          group_ids: [ group.id ])
      end
    end
    let!(:node2_2) do
      Timecop.freeze(now - 4.days) do
        create(
          :category_node_page, cur_site: site, filename: "name-2-2", shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ],
          group_ids: [])
      end
    end
    let!(:node3) do
      Timecop.freeze(now - 3.days) do
        create(
          :inquiry_node_form, cur_site: site, filename: "name-3", shortcuts: [ Cms::Node::SHORTCUT_SYSTEM ],
          group_ids: [ group.id ])
      end
    end

    it do
      # テスト開始時点ではキャッシュは存在しない
      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".list-item").tap do |links|
          expect(links).to have(3).items
          expect(links[0].css(".title").text).to eq node1.name
          expect(links[1].css(".title").text).to eq node2_1.name
          expect(links[2].css(".title").text).to eq node3.name
        end
        html.css(".pagination").tap do |pagination_element|
          expect(pagination_element).to be_blank
        end

        # 初回描画時でも最小限のDBアクセスで描画可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 2
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

      # user1 が閲覧可能なフォルダーを変更する（3つ見えるフォルダーのうちの真ん中を変更する）
      node2_1.without_record_timestamps do
        node2_1.update!(group_ids: [])
      end
      node2_2.without_record_timestamps do
        node2_2.update!(group_ids: [ group.id ])
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".list-item").tap do |links|
          expect(links).to have(3).items
          expect(links[0].css(".title").text).to eq node1.name
          expect(links[1].css(".title").text).to eq node2_2.name
          expect(links[2].css(".title").text).to eq node3.name
        end
        html.css(".pagination").tap do |pagination_element|
          expect(pagination_element).to be_blank
        end

        # 初回描画時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 2
      end
    end

    context "and keyword" do
      it do
        s = described_class::SearchParams.new(keyword: node1.name)

        # テスト開始時点ではキャッシュは存在しない
        described_class.new(cur_site: site, cur_user: user, s: s).tap do |component|
          expect(component.cache_exist?).to be_falsey
        end

        described_class.new(cur_site: site, cur_user: user, s: s).tap do |component|
          before_mongodb_count = MongoAccessCounter.succeeded_count

          html = render_inline component
          html.css(".list-item").tap do |links|
            expect(links).to have(1).items
            expect(links[0].css(".title").text).to eq node1.name
          end
          html.css(".pagination").tap do |pagination_element|
            expect(pagination_element).to be_blank
          end

          # 初回描画時でも最小限のDBアクセスで描画可能なことを確認
          after_mongodb_count = MongoAccessCounter.succeeded_count
          expect(after_mongodb_count - before_mongodb_count).to eq 2
        end

        described_class.new(cur_site: site, cur_user: user).tap do |component|
          # キーワードが指定されているので、キャッシュされない
          expect(component.cache_exist?).to be_falsey
        end
      end
    end

    context "and module" do
      it do
        s = described_class::SearchParams.new(mod: "category")

        # テスト開始時点ではキャッシュは存在しない
        described_class.new(cur_site: site, cur_user: user, s: s).tap do |component|
          expect(component.cache_exist?).to be_falsey
        end

        described_class.new(cur_site: site, cur_user: user, s: s).tap do |component|
          before_mongodb_count = MongoAccessCounter.succeeded_count

          html = render_inline component
          html.css(".list-item").tap do |links|
            expect(links).to have(1).items
            expect(links[0].css(".title").text).to eq node2_1.name
          end
          html.css(".pagination").tap do |pagination_element|
            expect(pagination_element).to be_blank
          end

          # 初回描画時でも最小限のDBアクセスで描画可能なことを確認
          after_mongodb_count = MongoAccessCounter.succeeded_count
          expect(after_mongodb_count - before_mongodb_count).to eq 2
        end

        described_class.new(cur_site: site, cur_user: user).tap do |component|
          # モジュールが指定されているので、キャッシュされない
          expect(component.cache_exist?).to be_falsey
        end
      end
    end

    context "and pagination" do
      before do
        @save_max_items_per_page = described_class.max_items_per_page
        described_class.max_items_per_page = 2
      end

      after do
        described_class.max_items_per_page = @save_max_items_per_page
      end

      it do
        # テスト開始時点ではキャッシュは存在しない
        described_class.new(cur_site: site, cur_user: user, page: nil).tap do |component|
          expect(component.cache_exist?).to be_falsey
        end

        described_class.new(cur_site: site, cur_user: user, page: nil).tap do |component|
          before_mongodb_count = MongoAccessCounter.succeeded_count

          html = render_inline component
          html.css(".list-item").tap do |links|
            expect(links).to have(2).items
            expect(links[0].css(".title").text).to eq node1.name
            expect(links[1].css(".title").text).to eq node2_1.name
          end
          html.css(".pagination").tap do |pagination_element|
            expect(pagination_element).to have(1).items
            expect(pagination_element.css(".first")).to be_blank
            expect(pagination_element.css(".prev")).to be_blank
            expect(pagination_element.css(".current")).to have(1).items
            expect(pagination_element.css(".next")).to have(1).items
            expect(pagination_element.css(".last")).to have(1).items
          end

          # 初回描画時でも最小限のDBアクセスで描画可能なことを確認
          after_mongodb_count = MongoAccessCounter.succeeded_count
          expect(after_mongodb_count - before_mongodb_count).to eq 2
        end

        described_class.new(cur_site: site, cur_user: user, page: nil).tap do |component|
          # 1ページ目はキャッシュされる
          expect(component.cache_exist?).to be_truthy
        end
        described_class.new(cur_site: site, cur_user: user, page: 1).tap do |component|
          # page の nil と 1 は同じ意味；キャッシュが応答される
          expect(component.cache_exist?).to be_truthy
        end
        described_class.new(cur_site: site, cur_user: user, page: 0).tap do |component|
          # page の nil と 0 は同じ意味；キャッシュが応答される
          expect(component.cache_exist?).to be_truthy
        end

        described_class.new(cur_site: site, cur_user: user, page: 2).tap do |component|
          # 2ページ目はキャッシュされない
          expect(component.cache_exist?).to be_falsey
        end
        described_class.new(cur_site: site, cur_user: user, page: 2).tap do |component|
          before_mongodb_count = MongoAccessCounter.succeeded_count

          html = render_inline component
          html.css(".list-item").tap do |links|
            expect(links).to have(1).items
            expect(links[0].css(".title").text).to eq node3.name
          end
          html.css(".pagination").tap do |pagination_element|
            expect(pagination_element).to have(1).items
            expect(pagination_element.css(".first")).to have(1).items
            expect(pagination_element.css(".prev")).to have(1).items
            expect(pagination_element.css(".current")).to have(1).items
            expect(pagination_element.css(".next")).to be_blank
            expect(pagination_element.css(".last")).to be_blank
          end

          # 初回描画時でも最小限のDBアクセスで描画可能なことを確認
          after_mongodb_count = MongoAccessCounter.succeeded_count
          expect(after_mongodb_count - before_mongodb_count).to eq 2
        end
        described_class.new(cur_site: site, cur_user: user, page: 2).tap do |component|
          # 2ページ目はキャッシュされない
          expect(component.cache_exist?).to be_falsey
        end
      end
    end
  end
end
