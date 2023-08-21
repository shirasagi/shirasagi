require 'spec_helper'

describe Cms::Column::Value::TextArea, type: :model, dbscope: :example do
  describe "what cms/column/value/text_area exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_text_area, cur_form: form, order: 1) }
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, value: "<p>#{unique_id}</p>\n<script>#{unique_id}</script>")
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
      expect(subject.html).to eq value.value.gsub("<script>", "").gsub("</script>", "").gsub("\n", "<br>")
      expect(subject.type).to eq described_class.name
      expect(subject.value).to eq value.value
    end
  end
end
