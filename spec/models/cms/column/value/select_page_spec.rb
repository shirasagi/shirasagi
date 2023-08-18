require 'spec_helper'

describe Cms::Column::Value::SelectPage, type: :model, dbscope: :example do
  describe "what cms/column/value/select_page exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }

    let(:node2) { create :article_node_page }
    let!(:selectable_page1) { create :article_page, cur_node: node2, state: 'public' }
    let!(:selectable_page2) { create :article_page, cur_node: node2, state: 'public' }
    let!(:selectable_page3) { create :article_page, cur_node: node2, state: 'public' }
    let!(:selectable_page4) { create :article_page, cur_node: node2, state: 'closed' }

    let!(:column1) do
      create(:cms_column_select_page, cur_form: form, order: 1, node_ids: [node2.id])
    end
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [column1.value_type.new(column: column1, page_id: selectable_page1.id)])
    end
    let!(:value) { page.column_values.first }
    let(:assigns) { {} }
    let(:registers) { { cur_site: cms_site } }
    let(:page_link) { "<a href=\"#{selectable_page1.url}\">#{selectable_page1.name}</a>" }

    subject { value.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    it do
      expect(subject.name).to eq column1.name
      expect(subject.alignment).to eq value.alignment
      expect(subject.page.name).to eq selectable_page1.name
      expect(subject.page_link).to eq page_link
    end
  end
end
