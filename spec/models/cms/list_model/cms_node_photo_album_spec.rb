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
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          # why wildcard is assumed? this must be incorrect
          expect(subject[0]).to include(filename: /^#{::Regexp.escape(node.filename)}\//)
        end
      end

      context "with existing node" do
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ article_node.filename ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 1
          expect(subject[0]).to include(
            filename: /^#{::Regexp.escape(article_node.filename)}\//, depth: article_node.depth + 1)
        end
      end

      context "with non-existing node" do
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ "node-#{unique_id}" ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 0 # this means `where("$or" => [])` and will cause system error because of invalid where
        end
      end

      context "with existing node as wildcard" do
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ "#{article_node.filename}/*" ] }
        subject { node.condition_hash["$or"] }

        it do
          # wildcard is not supported
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 0 # this means `where("$or" => [])` and will cause system error because of invalid where
        end
      end

      context "with non-existing node as wildcard" do
        let(:filename) { "node-#{unique_id}" }
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ "#{filename}/*" ] }
        subject { node.condition_hash["$or"] }

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 0 # this means `where("$or" => [])` and will cause system error because of invalid where
        end
      end

      context "when \#{request_dir} is given with blank cur_main_path" do
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ "\#{request_dir}" ] }
        subject do
          node.cur_main_path = nil
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 0 # this means `where("$or" => [])` and will cause system error because of invalid where
        end
      end

      context "when \#{request_dir} is given with actual cur_main_path" do
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ "\#{request_dir}" ] }
        subject do
          node.cur_main_path = "/#{article_node.filename}/index.html"
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 0 # this means `where("$or" => [])` and will cause system error because of invalid where
        end
      end

      context "when \#{request_dir} is given with non-existing cur_main_path" do
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ "\#{request_dir}" ] }
        subject do
          node.cur_main_path = "/node-#{unique_id}/index.html"
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 0 # this means `where("$or" => [])` and will cause system error because of invalid where
        end
      end

      context "when \#{request_dir} with sub directory is given with actual cur_main_path" do
        let(:condition) { "\#{request_dir}/#{::File.basename(article_node.filename)}" }
        let!(:node) { create :cms_node_photo_album, cur_site: site, layout: layout, conditions: [ condition ] }
        subject do
          node.cur_main_path = "/#{root_node.filename}/index.html"
          node.condition_hash["$or"]
        end

        it do
          expect(subject).to be_a(Array)
          expect(subject.length).to eq 0 # this means `where("$or" => [])` and will cause system error because of invalid where
        end
      end
    end
  end
end
