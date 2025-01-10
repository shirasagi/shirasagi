require 'spec_helper'

describe Cms::Addon::List::Model do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:root_node) { create :cms_node_node, cur_site: site, layout: layout }
  let!(:article_node) { create :article_node_page, cur_site: site, cur_node: root_node, layout: layout }
  let!(:article_page) { create :article_page, cur_site: site, cur_node: article_node, layout: layout }

  describe "#condition_hash" do
    context "on a node 'cms/node'" do
      context "with empty conditions" do
        let!(:node) { create :facility_node_service, cur_site: site, layout: layout, conditions: [] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to eq(
            site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
          # category key is "service_ids"
          expect(subject[1]).to eq(site_id: site.id, service_ids: node.id)
        end
      end

      context "with existing node" do
        let!(:node) { create :facility_node_service, cur_site: site, layout: layout, conditions: [ article_node.filename ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 3
          expect(subject[0]).to eq(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
          expect(subject[1]).to eq(
            site_id: site.id, filename: /^#{::Regexp.escape(article_node.filename)}\//, depth: article_node.depth + 1)
          # category key is "service_ids"
          expect(subject[2]).to eq(site_id: site.id, service_ids: { "$in" => [ node.id, article_node.id ] })
        end
      end

      context "inter-site reference" do
        let(:site1) { create(:cms_site_subdir, parent: site) }
        let(:site1_layout) { create_cms_layout(cur_site: site1) }
        let!(:site1_root_node) { create :cms_node_node, cur_site: site1, layout: site1_layout }
        let!(:site1_article_node) do
          create :article_node_page, cur_site: site1, cur_node: site1_root_node, layout: site1_layout
        end

        let(:condition) { "#{site1.host}:#{site1_article_node.filename}" }
        let!(:node) { create :facility_node_service, cur_site: site, layout: layout, conditions: [ condition ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 4
          expect(subject[0]).to eq(
            site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
          expect(subject[1]).to eq(
            site_id: site1.id, filename: /^#{::Regexp.escape(site1_article_node.filename)}\//,
            depth: site1_article_node.depth + 1)
          # category key is "service_ids"
          expect(subject[2]).to eq(site_id: site.id, service_ids: node.id)
          expect(subject[3]).to eq(site_id: site1.id, service_ids: site1_article_node.id)
        end
      end
    end
  end
end
