require 'spec_helper'

describe Cms::Column::Value::List, type: :model, dbscope: :example do
  describe "what cms/column/value/text_field exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_list, cur_form: form, order: 1) }
    let(:lists) { Array.new(3) { "<p>#{unique_id}</p><script>#{unique_id}</script>" } }
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, lists: lists)
        ]
      )
    end
    let!(:value) { page.column_values.first }
    let(:assigns) { {} }
    let(:registers) { { cur_site: cms_site } }
    subject { value.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    it do
      expect(subject.name).to eq column1.name
      expect(subject.alignment).to eq value.alignment
      list_body = lists.map { |li| "<li>#{li.gsub(/<\/?script>/, "")}</li>" }.join("\n")
      expect(subject.html).to eq "<#{column1.list_type}>#{list_body}</#{column1.list_type}>"
      expect(subject.type).to eq described_class.name
      expect(subject.list_type).to eq column1.list_type
      expect(subject.lists).to eq lists
    end
  end
end
