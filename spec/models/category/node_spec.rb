require 'spec_helper'

describe Category::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :category_node_base }
  it_behaves_like "cms_node#spec"
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
end

describe Category::Node::Page, type: :model, dbscope: :example do
  let(:item) { create :category_node_page }
  it_behaves_like "cms_node#spec"
end
