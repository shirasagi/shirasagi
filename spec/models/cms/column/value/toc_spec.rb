require 'spec_helper'

describe Cms::Column::Value::Toc, type: :model, dbscope: :example do
  let!(:node) { create :article_node_page }
  let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }

  describe 'to_default_html' do
    context 'with anchor-enabled headlines' do
      let!(:headline_column) do
        create(:cms_column_headline, cur_form: form, order: 1,
               min_headline_level: 'h2', max_headline_level: 'h4',
               enable_anchor: 'enabled')
      end
      let!(:toc_column) { create(:cms_column_toc, cur_form: form, order: 2) }
      let!(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            headline_column.value_type.new(column: headline_column, head: 'h2', text: 'First', anchor: 'first', order: 1),
            headline_column.value_type.new(column: headline_column, head: 'h3', text: 'Second', order: 2),
            toc_column.value_type.new(column: toc_column, order: 3)
          ]
        )
      end

      let(:toc_value) { page.column_values.detect { |v| v.is_a?(described_class) } }
      let(:headline_values) { page.column_values.select { |v| v.is_a?(Cms::Column::Value::Headline) }.sort_by(&:order) }

      it 'generates a nav with links to each headline anchor' do
        html = toc_value.to_html
        expect(html).to include('<nav')
        expect(html).to include('href="#first"')
        expect(html).to include('First')
        expect(html).to include('href="#headline-2"')
        expect(html).to include('Second')
      end

      it 'produces hrefs that match the ids emitted by the headlines' do
        headline_values.each do |hl|
          headline_html = hl.to_html
          expect(headline_html).to include(%(id="#{hl.resolved_anchor}"))
          expect(toc_value.to_html).to include(%(href="##{hl.resolved_anchor}"))
        end
      end
    end

    context 'when headlines do not have the anchor feature enabled' do
      let!(:headline_column) do
        create(:cms_column_headline, cur_form: form, order: 1,
               min_headline_level: 'h2', max_headline_level: 'h4')
      end
      let!(:toc_column) { create(:cms_column_toc, cur_form: form, order: 2) }
      let!(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            headline_column.value_type.new(column: headline_column, head: 'h2', text: 'First', order: 1),
            toc_column.value_type.new(column: toc_column, order: 2)
          ]
        )
      end

      let(:toc_value) { page.column_values.detect { |v| v.is_a?(described_class) } }

      it 'renders an empty table of contents' do
        expect(toc_value.to_html).to eq ''
      end
    end

    context 'with a headline level outside the toc target range' do
      let!(:headline_column) do
        create(:cms_column_headline, cur_form: form, order: 1,
               min_headline_level: 'h2', max_headline_level: 'h4',
               enable_anchor: 'enabled')
      end
      let!(:toc_column) do
        create(:cms_column_toc, cur_form: form, order: 2,
               min_headline_level: 'h2', max_headline_level: 'h2')
      end
      let!(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            headline_column.value_type.new(column: headline_column, head: 'h2', text: 'Included', anchor: 'in', order: 1),
            headline_column.value_type.new(column: headline_column, head: 'h3', text: 'Excluded', anchor: 'out', order: 2),
            toc_column.value_type.new(column: toc_column, order: 3)
          ]
        )
      end

      let(:toc_value) { page.column_values.detect { |v| v.is_a?(described_class) } }

      it 'only includes headlines within the configured level range' do
        html = toc_value.to_html
        expect(html).to include('href="#in"')
        expect(html).to include('Included')
        expect(html).not_to include('href="#out"')
        expect(html).not_to include('Excluded')
      end
    end
  end
end
