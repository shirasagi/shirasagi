require 'spec_helper'

describe Cms::Content do
  let(:site) { cms_site }

  describe "#public_list" do
    context "in node 'article/page'" do
      context "part 'article/page' on root" do
        let!(:part) { create :article_part_page, cur_site: site, conditions: conditions }
        let!(:node1) { create :article_node_page, cur_site: site }
        let!(:node2) { create :article_node_page, cur_site: site }
        let!(:node3) { create :article_node_page, cur_site: site }
        let!(:date) { Time.zone.now }
        let!(:page1) { create :article_page, cur_site: site, cur_node: node1 }
        let!(:page2) { create :article_page, cur_site: site, cur_node: node2 }
        let!(:page3) { create :cms_page, cur_site: site }

        context "with empty conditions" do
          let!(:conditions) { [] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array []
          end
        end

        context "with node2" do
          let!(:conditions) { [node2.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page2.id]
          end
        end

        context "with node3" do
          let!(:conditions) { [node3.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array []
          end
        end
      end

      context "part 'article/page' on a node" do
        let!(:part) { create :article_part_page, cur_node: node1, cur_site: site, conditions: conditions }
        let!(:node1) { create :article_node_page, cur_site: site }
        let!(:node2) { create :article_node_page, cur_site: site }
        let!(:node3) { create :article_node_page, cur_site: site }
        let!(:date) { Time.zone.now }
        let!(:page1) { create :article_page, cur_site: site, cur_node: node1 }
        let!(:page2) { create :article_page, cur_site: site, cur_node: node2 }
        let!(:page3) { create :cms_page, cur_site: site }

        context "with empty conditions" do
          let!(:conditions) { [] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page1.id]
          end
        end

        context "with node2" do
          let!(:conditions) { [node2.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page1.id, page2.id]
          end
        end

        context "with node3" do
          let!(:conditions) { [node3.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page1.id]
          end
        end
      end
    end

    context "in node 'category/page'" do
      context "part 'article/page' on root" do
        let!(:part) { create :article_part_page, cur_site: site, conditions: conditions }
        let!(:node) { create :article_node_page, cur_site: site }
        let!(:cate1) { create :article_node_page, cur_site: site }
        let!(:cate2) { create :article_node_page, cur_site: site }
        let!(:cate3) { create :article_node_page, cur_site: site }
        let!(:date) { Time.zone.now }
        let!(:page1) { create :article_page, cur_site: site, cur_node: node, category_ids: [cate1.id] }
        let!(:page2) { create :article_page, cur_site: site, cur_node: node, category_ids: [cate2.id] }
        let!(:page3) { create :cms_page, cur_site: site }

        context "with empty conditions" do
          let!(:conditions) { [] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array []
          end
        end

        context "with node2" do
          let!(:conditions) { [cate2.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page2.id]
          end
        end

        context "with node3" do
          let!(:conditions) { [cate3.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array []
          end
        end
      end

      context "part 'article/page' on root" do
        let!(:part) { create :article_part_page, cur_site: site, cur_node: cate1, conditions: conditions }
        let!(:node) { create :article_node_page, cur_site: site }
        let!(:cate1) { create :article_node_page, cur_site: site }
        let!(:cate2) { create :article_node_page, cur_site: site }
        let!(:cate3) { create :article_node_page, cur_site: site }
        let!(:date) { Time.zone.now }
        let!(:page1) { create :article_page, cur_site: site, cur_node: node, category_ids: [cate1.id] }
        let!(:page2) { create :article_page, cur_site: site, cur_node: node, category_ids: [cate2.id] }
        let!(:page3) { create :cms_page, cur_site: site }

        context "with empty conditions" do
          let!(:conditions) { [] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page1.id]
          end
        end

        context "with node2" do
          let!(:conditions) { [cate2.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page1.id, page2.id]
          end
        end

        context "with node3" do
          let!(:conditions) { [cate3.filename] }

          it do
            ids = Article::Page.public_list(site: site, part: part, date: date).pluck(:id)
            expect(ids).to match_array [page1.id]
          end
        end
      end
    end
  end
end
