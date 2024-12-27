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
      let!(:component) { described_class.new(site: site, user: user, cache_mode: cache_mode) }

      it do
        html = render_inline component
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

        expect(component.cache_exist?).to be_falsey
      end
    end

    context "cache enabled" do
      let(:perform_caching) { true }

      it do
        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          expect(component.cache_exist?).to be_falsey

          render_inline component

          expect(component.cache_exist?).to be_truthy
        end

        described_class.new(site: site, user: user, cache_mode: cache_mode).tap do |component|
          before_mongodb_count = MongoAccessCounter.succeeded_count

          render_inline component

          # 最小限のDBアクセスでキャッシュを利用可能なことを確認
          after_mongodb_count = MongoAccessCounter.succeeded_count
          expect(after_mongodb_count).to eq before_mongodb_count + 1
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
end
