require 'spec_helper'

describe Cms::Column::Value::Headline, type: :model, dbscope: :example do
  describe "what cms/column/value/headline exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_headline, cur_form: form, order: 1) }
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, head: "h1", text: "<p>#{unique_id}</p><script>#{unique_id}</script>")
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
      expect(subject.html).to eq "<h1>#{value.text.gsub("<script>", "").gsub("</script>", "")}</h1>"
      expect(subject.type).to eq described_class.name
      expect(subject.head).to eq value.head
      expect(subject.text).to eq value.text
    end
  end

  describe 'head inclusion validation' do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'entry') }

    context 'with a new-default column (h2-h4)' do
      let!(:column) do
        create(:cms_column_headline,
               cur_form: form, order: 1,
               min_headline_level: 'h2', max_headline_level: 'h4')
      end

      it 'rejects head outside the range (h1)' do
        value = column.value_type.new(column: column, head: 'h1', text: 'sample')
        expect(value).not_to be_valid
        expect(value.errors[:head]).not_to be_empty
      end

      it 'rejects head outside the range (h5)' do
        value = column.value_type.new(column: column, head: 'h5', text: 'sample')
        expect(value).not_to be_valid
      end

      it 'accepts head within the range (h3)' do
        value = column.value_type.new(column: column, head: 'h3', text: 'sample')
        expect(value).to be_valid
      end
    end

    context 'with a legacy column (min/max nil)' do
      let!(:column) { create(:cms_column_headline, cur_form: form, order: 1) }

      it 'accepts head h1 (backward compatibility)' do
        value = column.value_type.new(column: column, head: 'h1', text: 'sample')
        expect(value).to be_valid
      end

      it 'accepts head h4' do
        value = column.value_type.new(column: column, head: 'h4', text: 'sample')
        expect(value).to be_valid
      end

      it 'rejects head h5 (outside legacy range)' do
        value = column.value_type.new(column: column, head: 'h5', text: 'sample')
        expect(value).not_to be_valid
      end
    end
  end

  describe '#import_csv_cell' do
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'entry') }

    context 'with a new-default column' do
      let!(:column) do
        create(:cms_column_headline,
               cur_form: form, order: 1,
               min_headline_level: 'h2', max_headline_level: 'h4')
      end

      it 'defaults head to the column min (h2)' do
        value = column.value_type.new(column: column)
        value.import_csv_cell('sample text')
        expect(value.head).to eq 'h2'
        expect(value.text).to eq 'sample text'
      end
    end

    context 'with a legacy column' do
      let!(:column) { create(:cms_column_headline, cur_form: form, order: 1) }

      it 'defaults head to h1 (legacy)' do
        value = column.value_type.new(column: column)
        value.import_csv_cell('sample text')
        expect(value.head).to eq 'h1'
      end
    end
  end
end
