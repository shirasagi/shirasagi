require 'spec_helper'

describe Category::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :category_node_base }
  it_behaves_like "cms_node#spec"

  describe ".tree_sort" do
    let!(:cate0) { create :category_node_node }
    let!(:cate1) { create :category_node_node, cur_node: cate0, order: 10, basename: "cate1" }
    let!(:cate2) { create :category_node_node, cur_node: cate0, order: 20, basename: "cate2" }
    let!(:cate11) { create :category_node_page, cur_node: cate1, order: 30, basename: "cate11" }
    let!(:cate12) { create :category_node_page, cur_node: cate1, order: 40, basename: "cate12" }
    let!(:cate21) { create :category_node_page, cur_node: cate2, order: 50, basename: "cate21" }
    let!(:cate22) { create :category_node_page, cur_node: cate2, order: 60, basename: "cate22" }

    it do
      categories = Category::Node::Base.all.where(filename: /#{cate0.filename}/).tree_sort
      categories = categories.to_a
      expect(categories.count).to eq 7
      expect(categories[0].id).to eq cate0.id
      expect(categories[1].id).to eq cate1.id
      expect(categories[2].id).to eq cate11.id
      expect(categories[3].id).to eq cate12.id
      expect(categories[4].id).to eq cate2.id
      expect(categories[5].id).to eq cate21.id
      expect(categories[6].id).to eq cate22.id
    end
  end
end

describe Category::Node::Node, type: :model, dbscope: :example do
  let(:item) { create :category_node_node }
  it_behaves_like "cms_node#spec"

  describe '#render_loop_html - pages.count' do
    let(:category) { create :category_node_page, cur_node: item }
    let!(:page) { create(:article_page, category_ids: [ category.id ]) }

    it do
      expect(item.render_loop_html(category, html: '#{pages.count}')).to eq('1')
    end
  end

  context 'when child_limit is 10' do
    let(:category) { create :category_node_node, cur_node: item, child_limit: 10 }

    it do
      expect(item.child_limit).to eq(5)
      expect(category.child_limit).to eq(10)
    end
  end

  context 'when child_limit is negative' do
    let(:category) { create :category_node_node, cur_node: item, child_limit: -1 }

    it do
      expect(item.child_limit).to eq(5)
      expect(category.child_limit).to eq(0)
    end
  end
end

describe Category::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :category_node_page }
  it_behaves_like "cms_node#spec"
end
