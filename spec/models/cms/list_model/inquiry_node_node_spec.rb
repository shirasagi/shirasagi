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
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "with existing node" do
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ article_node.filename ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(site_id: site.id, filename: article_node.filename)
          # the default location is always contained
          expect(subject[1]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "with non-existing node" do
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ "node-#{unique_id}" ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # the default location is always contained
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "with existing node as wildcard" do
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ "#{article_node.filename}/*" ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(article_node.filename)}\//)
          # the default location is always contained
          expect(subject[1]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "with non-existing node as wildcard" do
        let(:filename) { "node-#{unique_id}" }
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ "#{filename}/*" ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(filename)}\//)
          # the default location is always contained
          expect(subject[1]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "when \#{request_dir} is given with blank cur_main_path" do
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ "\#{request_dir}" ] }
        subject do
          node.cur_main_path = nil
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # the default location is always contained
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "when \#{request_dir} is given with actual cur_main_path" do
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ "\#{request_dir}" ] }
        subject do
          node.cur_main_path = "/#{article_node.filename}/index.html"
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # the default location is always contained
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "when \#{request_dir} is given with non-existing cur_main_path" do
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ "\#{request_dir}" ] }
        subject do
          node.cur_main_path = "/node-#{unique_id}/index.html"
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # the default location is always contained
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end

      context "when \#{request_dir} with sub directory is given with actual cur_main_path" do
        let(:condition) { "\#{request_dir}/#{::File.basename(article_node.filename)}" }
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ condition ] }
        subject do
          node.cur_main_path = "/#{root_node.filename}/index.html"
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # the default location is always contained
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
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
        let!(:node) { create :inquiry_node_node, cur_site: site, layout: layout, conditions: [ condition ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(site_id: site1.id, filename: site1_article_node.filename)
          # the default location is always contained
          expect(subject[1]).to include(
            site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1)
        end
      end
    end
  end
end
