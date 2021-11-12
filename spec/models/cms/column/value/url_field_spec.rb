require 'spec_helper'

describe Cms::Column::Value::UrlField, type: :model, dbscope: :example do
  describe "what cms/column/value/url_field exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_url_field, cur_form: form, order: 1, html_tag: 'a') }
    let(:url) { "/#{unique_id}/" }
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, value: "Link To,#{url}")
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
      expect(subject.html).to eq "<a href=\"#{url}\">Link To</a>"
      expect(subject.type).to eq described_class.name
      expect(subject.value).to eq "Link To,#{url}"
      expect(subject.link).to eq url
      expect(subject.label).to eq "Link To"
    end

    context 'when value is blank' do
      let!(:column1) { create(:cms_column_url_field, cur_form: form, order: 1, required: 'optional') }
      let!(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(column: column1)
          ]
        )
      end

      it do
        expect(subject.name).to eq column1.name
        expect(subject.alignment).to eq value.alignment
        expect(subject.html).to be_blank
        expect(subject.type).to eq described_class.name
        expect(subject.value).to be_nil
        expect(subject.link).to be_nil
        expect(subject.label).to be_nil
      end
    end
  end
end
