require 'spec_helper'

describe Cms::Column::Value::UrlField2, type: :model, dbscope: :example do
  describe "what cms/column/value/date_field exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_url_field2, cur_form: form, order: 1) }
    let(:url) { "http://#{unique_id}.example.jp/#{unique_id}/" }
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, link_url: url, link_label: "Link To")
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
      expect(subject.link_url).to eq url
      expect(subject.link_label).to eq "Link To"
      expect(subject.link_target).to be_blank
    end
  end
end
