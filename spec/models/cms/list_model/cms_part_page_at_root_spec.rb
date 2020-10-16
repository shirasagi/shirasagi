require 'spec_helper'

describe Cms::Addon::List::Model do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:root_node) { create :cms_node_node, cur_site: site, layout: layout }
  let!(:article_node) { create :article_node_page, cur_site: site, cur_node: root_node, layout: layout }
  let!(:article_page) { create :article_page, cur_site: site, cur_node: article_node, layout: layout }

  describe "#condition_hash" do
    context "on a part 'cms/page'" do
      context "with empty conditions" do
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [] }
        subject { part.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          expect(subject[0]).to include(site_id: site.id, filename: /^[^\/]+$/, depth: 1)
        end
      end

      context "with existing node" do
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ article_node.filename ] }
        subject { part.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 3
          expect(subject[0]).to include(
            site_id: site.id, filename: /^#{::Regexp.escape(article_node.filename)}\//, depth: article_node.depth + 1)
          expect(subject[1]).to include(site_id: site.id, filename: /^[^\/]+$/, depth: 1)
          expect(subject[2]).to include(site_id: site.id, category_ids: article_node.id)
        end
      end

      context "with non-existing node" do
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ "node-#{unique_id}" ] }
        subject { part.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          expect(subject[0]).to include(site_id: site.id, filename: /^[^\/]+$/, depth: 1)
        end
      end

      context "with existing node as wildcard" do
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ "#{article_node.filename}/*" ] }
        subject { part.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(article_node.filename)}\//)
          expect(subject[1]).to include(site_id: site.id, filename: /^[^\/]+$/, depth: 1)
        end
      end

      context "with non-existing node as wildcard" do
        let(:filename) { "node-#{unique_id}" }
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ "#{filename}/*" ] }
        subject { part.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(site_id: site.id, filename: /^#{::Regexp.escape(filename)}\//)
          expect(subject[1]).to include(site_id: site.id, filename: /^[^\/]+$/, depth: 1)
        end
      end

      context "when \#{request_dir} is given with blank cur_main_path" do
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ "\#{request_dir}" ] }
        subject do
          part.cur_main_path = nil
          part.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          expect(subject[0]).to include(site_id: site.id, filename: /^[^\/]+$/, depth: 1)
        end
      end

      context "when \#{request_dir} is given with actual cur_main_path" do
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ "\#{request_dir}" ] }
        subject do
          part.cur_main_path = "/#{article_node.filename}/index.html"
          part.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(
            site_id: site.id, filename: /^#{::Regexp.escape(article_node.filename)}\//, depth: article_node.depth + 1)
          expect(subject[1]).to include(site_id: site.id, category_ids: article_node.id)
        end
      end

      context "when \#{request_dir} is given with non-existing cur_main_path" do
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ "\#{request_dir}" ] }
        subject do
          part.cur_main_path = "/node-#{unique_id}/index.html"
          part.condition_hash["$and"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          expect(subject[0]).to eq(id: -1)
        end
      end

      context "when \#{request_dir} with sub directory is given with actual cur_main_path" do
        let(:condition) { "\#{request_dir}/#{::File.basename(article_node.filename)}" }
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ condition ] }
        subject do
          part.cur_main_path = "/#{root_node.filename}/index.html"
          part.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 2
          expect(subject[0]).to include(
            site_id: site.id, filename: /^#{::Regexp.escape(article_node.filename)}\//, depth: article_node.depth + 1)
          expect(subject[1]).to include(site_id: site.id, category_ids: article_node.id)
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
        let!(:part) { create :cms_part_page, cur_site: site, conditions: [ condition ] }
        subject { part.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 3
          expect(subject[0]).to include(
            site_id: site1.id,
            filename: /^#{::Regexp.escape(site1_article_node.filename)}\//, depth: site1_article_node.depth + 1)
          expect(subject[1]).to include(site_id: site.id, filename: /^[^\/]+$/, depth: 1)
          expect(subject[2]).to include(site_id: site1.id, category_ids: site1_article_node.id)
        end
      end
    end
  end
end
