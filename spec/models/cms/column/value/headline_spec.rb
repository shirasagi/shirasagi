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

  describe '#resolved_anchor and to_default_html (anchor feature)' do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }

    context 'when anchor feature is disabled (default)' do
      let!(:column) do
        create(:cms_column_headline, cur_form: form, order: 1,
               min_headline_level: 'h2', max_headline_level: 'h4')
      end
      let!(:page) do
        create(:article_page, cur_node: node, form: form,
               column_values: [ column.value_type.new(column: column, head: 'h2', text: 'Section') ])
      end

      it 'does not emit an id attribute' do
        value = page.column_values.first
        expect(value.to_html).not_to include('id=')
      end
    end

    context 'when anchor feature is enabled' do
      let!(:column) do
        create(:cms_column_headline, cur_form: form, order: 1,
               min_headline_level: 'h2', max_headline_level: 'h4',
               enable_anchor: 'enabled')
      end

      context 'with an explicit anchor' do
        let!(:page) do
          create(:article_page, cur_node: node, form: form,
                 column_values: [ column.value_type.new(column: column, head: 'h2', text: 'Section', anchor: 'intro') ])
        end

        it 'uses the given anchor as the resolved id' do
          value = page.column_values.first
          expect(value.resolved_anchor).to eq 'intro'
          expect(value.to_html).to include('id="intro"')
        end
      end

      context 'without an explicit anchor' do
        let!(:page) do
          create(:article_page, cur_node: node, form: form,
                 column_values: [
                   column.value_type.new(column: column, head: 'h2', text: 'First', order: 1),
                   column.value_type.new(column: column, head: 'h3', text: 'Second', order: 2)
                 ])
        end

        it 'falls back to deterministic headline-N ids' do
          values = page.column_values.sort_by(&:order)
          expect(values[0].resolved_anchor).to eq 'headline-1'
          expect(values[1].resolved_anchor).to eq 'headline-2'
        end
      end

      context 'with an anchor containing invalid characters' do
        it 'is invalid' do
          value = column.value_type.new(column: column, head: 'h2', text: 'Section', anchor: '見出し')
          expect(value).not_to be_valid
          expect(value.errors[:anchor]).not_to be_empty
        end
      end

      context 'with a duplicate anchor within the page' do
        let!(:page) do
          create(:article_page, cur_node: node, form: form,
                 column_values: [
                   column.value_type.new(column: column, head: 'h2', text: 'First', anchor: 'dup', order: 1)
                 ])
        end

        it 'rejects a second value reusing the same anchor' do
          page.column_values << column.value_type.new(column: column, head: 'h3', text: 'Second', anchor: 'dup', order: 2)
          dup_value = page.column_values.last
          expect(dup_value).not_to be_valid
          expect(dup_value.errors[:anchor]).not_to be_empty
        end
      end

      context 'when an explicit anchor collides with another headline fallback id' do
        let!(:page) do
          create(:article_page, cur_node: node, form: form,
                 column_values: [
                   column.value_type.new(column: column, head: 'h2', text: 'First', anchor: 'headline-2', order: 1)
                 ])
        end

        it 'rejects the blank-anchor headline whose fallback id matches the explicit one' do
          # Second headline has no explicit anchor; its fallback resolves to "headline-2",
          # which collides with the first headline's explicit anchor.
          page.column_values << column.value_type.new(column: column, head: 'h3', text: 'Second', order: 2)
          blank_value = page.column_values.last
          expect(blank_value.resolved_anchor).to eq 'headline-2'
          expect(blank_value).not_to be_valid
          expect(blank_value.errors[:anchor]).not_to be_empty
        end
      end
    end
  end
end
