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
        let!(:node) { create :garbage_node_search, cur_site: site, layout: layout, conditions: [] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # wildcard is assumed. key `:depth` isn't contained
          expect(subject[0]).to eq(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//)
          # and there are no category references
        end
      end

      context "with existing node" do
        let!(:node) { create :garbage_node_search, cur_site: site, layout: layout, conditions: [ article_node.filename ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # wildcard is assumed. key `:depth` isn't contained
          expect(subject[0]).to eq(site_id: site.id, filename: /^#{::Regexp.escape(article_node.filename)}\//)
          # and there are no category references
        end
      end
    end
  end
end
