require 'spec_helper'

describe Cms::Column::Value::Youtube, type: :model, dbscope: :example do
  describe "what cms/column/value/youtube exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_youtube, cur_form: form, order: 1) }
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(
            column: column1, url: "https://www.youtube.com/watch?v=CSlLndeDc48", width: 640, height: 400
          )
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
      expect(subject.html).to eq value.youtube_iframe
      expect(subject.type).to eq described_class.name
      expect(subject.youtube_id).to eq "CSlLndeDc48"
      expect(subject.width).to eq 640
      expect(subject.height).to eq 400
      expect(subject.auto_width).to eq value.auto_width
    end
  end
end
