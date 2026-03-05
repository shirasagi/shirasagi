require 'spec_helper'

describe Cms::NodesTreeComponent, type: :component, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let(:cache_mode) { nil }
  let(:perform_caching) { false }

  around do |example|
    save_perform_caching = described_class.perform_caching
    described_class.perform_caching = perform_caching

    # role をウォーミングアップしておく
    user.cms_role_permit_any?(site, :read_private_cms_nodes)

    with_request_url("/.s#{site.id}/cms/nodes") do
      example.run
    end

    described_class.perform_caching = save_perform_caching
    Rails.cache.clear
  end

  context "simple test" do
    let!(:node1) { create :article_node_page, cur_site: site }
    let!(:node1_1) { create :cms_node_archive, cur_site: site, cur_node: node1 }
    let!(:node1_2) { create :cms_node_photo_album, cur_site: site, cur_node: node1 }
    let!(:node2) { create :cms_node_page, cur_site: site }
    let!(:node3) { create :inquiry_node_node, cur_site: site }
    let!(:node3_1) { create :inquiry_node_form, cur_site: site, cur_node: node3 }

    context "cache disabled" do
      it do
        # テスト開始時点ではキャッシュは存在しない
        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          expect(component.cache_exist?).to be_falsey
        end

        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline described_class.new(site: site, user: user, cache_mode: cache_mode)
        # puts html
        html.css("a[href='/.s#{site.id}/article#{node1.id}/pages']").tap do |anchors|
          expect(anchors).to have(1).items
          expect(anchors[0].text.strip).to eq node1.name
        end
        html.css("a[href='/.s#{site.id}/cms#{node1_1.id}/archives']").tap do |anchors|
          expect(anchors).to have(1).items
          expect(anchors[0].text.strip).to eq node1_1.name
        end
        html.css("a[href='/.s#{site.id}/cms#{node1_2.id}/photo_albums']").tap do |anchors|
          expect(anchors).to have(1).items
          expect(anchors[0].text.strip).to eq node1_2.name
        end
        html.css("a[href='/.s#{site.id}/cms#{node2.id}/pages']").tap do |anchors|
          expect(anchors).to have(1).items
          expect(anchors[0].text.strip).to eq node2.name
        end
        html.css("a[href='/.s#{site.id}/inquiry#{node3.id}/nodes']").tap do |anchors|
          expect(anchors).to have(1).items
          expect(anchors[0].text.strip).to eq node3.name
        end
        html.css("a[href='/.s#{site.id}/inquiry#{node3_1.id}/forms']").tap do |anchors|
          expect(anchors).to have(1).items
          expect(anchors[0].text.strip).to eq node3_1.name
        end

        # キャッシュ無効時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1

        # キャッシュは無効なので、テスト終了時点でもキャッシュは存在しない
        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          expect(component.cache_exist?).to be_falsey
        end
      end
    end

    context "cache enabled" do
      let(:perform_caching) { true }

      it do
        # テスト開始時点ではキャッシュは存在しない
        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          expect(component.cache_exist?).to be_falsey
        end

        before_mongodb_count = MongoAccessCounter.succeeded_count

        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          render_inline component
        end

        # キャッシュ無効時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1

        # キャッシュは有効なので、テスト終了時点でキャッシュが存在する
        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          expect(component.cache_exist?).to be_truthy
        end

        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          before_mongodb_count = MongoAccessCounter.succeeded_count

          render_inline component

          # キャッシュ存在時、最小限のDBアクセスでキャッシュを利用可能なことを確認
          after_mongodb_count = MongoAccessCounter.succeeded_count
          expect(after_mongodb_count - before_mongodb_count).to eq 1
        end
      end
    end

    context "cache enabled with super reload" do
      let(:perform_caching) { true }
      let(:cache_mode) { "refresh" }

      it do
        before_cache_entry = nil
        Timecop.freeze(now - 5.minutes) do
          described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
            expect(component.cache_exist?).to be_falsey

            render_inline component

            expect(component.cache_exist?).to be_truthy

            cache_key = component.send(:component_cache_key)
            cache_key = Rails.cache.send(:normalize_key, cache_key, nil)
            before_cache_entry = Rails.cache.send(:read_entry, cache_key)
            expect(before_cache_entry).to be_present
          end
        end

        Timecop.freeze(now) do
          described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
            render_inline component
            expect(component.cache_exist?).to be_truthy

            cache_key = component.send(:component_cache_key)
            cache_key = Rails.cache.send(:normalize_key, cache_key, nil)
            cache_entry = Rails.cache.send(:read_entry, cache_key)
            expect(cache_entry.expires_at).to be > before_cache_entry.expires_at
          end
        end
      end
    end
  end

  context "when a user doesn't have read permission to root folder" do
    let!(:editor_role) do
      permissions = %w(read_private_cms_nodes read_private_article_pages edit_private_article_pages)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:group0) { cms_group }
    let!(:editor_group) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
    let!(:editor) { create :cms_test_user, cms_role_ids: [ editor_role.id ], group_ids: [ editor_group.id ] }
    let(:perform_caching) { true }

    let!(:node1) { create :cms_node_node, cur_site: site, group_ids: user.group_ids }
    let!(:node1_1) { create :article_node_page, cur_site: site, cur_node: node1, group_ids: [ editor_group.id ] }

    before do
      expect(node1.allowed?(:read, editor, site: site)).to be_falsey
      expect(node1_1.allowed?(:read, editor, site: site)).to be_truthy
    end

    it do
      html = render_inline described_class.new(site: site, user: editor, cache_mode: cache_mode)
      # puts html
      html.css(".ss-tree-item[data-node-id='#{node1.id}']").tap do |tree_items|
        expect(tree_items).to have(1).items
      end
      html.css(".ss-tree-item[data-node-id='#{node1_1.id}']").tap do |tree_items|
        expect(tree_items).to have(1).items
      end
      html.css("a[href='/.s#{site.id}/cms#{node1.id}/nodes']").tap do |anchors|
        expect(anchors).to have(0).items
      end
      html.css("a[href='/.s#{site.id}/article#{node1_1.id}/pages']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text.strip).to eq node1_1.name
      end

      html = render_inline described_class.new(site: site, user: user, cache_mode: cache_mode)
      # puts html
      html.css(".ss-tree-item[data-node-id='#{node1.id}']").tap do |tree_items|
        expect(tree_items).to have(1).items
      end
      html.css(".ss-tree-item[data-node-id='#{node1_1.id}']").tap do |tree_items|
        expect(tree_items).to have(1).items
      end
      html.css("a[href='/.s#{site.id}/cms#{node1.id}/nodes']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text.strip).to eq node1.name
      end
      html.css("a[href='/.s#{site.id}/article#{node1_1.id}/pages']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text.strip).to eq node1_1.name
      end
    end
  end

  context "when some mid-level folders are missing" do
    let(:perform_caching) { true }

    let!(:node1) { create :cms_node_node, cur_site: site }
    let!(:node1_1) { create :article_node_page, cur_site: site, cur_node: node1 }

    before do
      node1.delete
      expect { node1_1.reload }.not_to raise_error
    end

    it do
      html = render_inline described_class.new(site: site, user: user, cache_mode: cache_mode)
      # puts html
      html.css(".ss-tree-item[data-node-id='not_found']").tap do |tree_items|
        expect(tree_items).to have(1).items
      end
      html.css(".ss-tree-item[data-node-id='#{node1_1.id}']").tap do |tree_items|
        expect(tree_items).to have(1).items
      end
      html.css("a[href='/.s#{site.id}/cms#{node1.id}/nodes']").tap do |anchors|
        expect(anchors).to have(0).items
      end
      html.css("a[href='/.s#{site.id}/article#{node1_1.id}/pages']").tap do |anchors|
        expect(anchors).to have(1).items
        expect(anchors[0].text.strip).to eq node1_1.name
      end
    end
  end
end
