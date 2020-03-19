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

  describe "validation" do
    let(:domain) { cms_site.domains.first }
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_url_field2, cur_form: form, order: 1) }

    let!(:article_node) { create :article_node_page, filename: "docs" }
    let!(:article_page) { create :article_page, cur_node: article_node, basename: "page1.html" }

    let(:valid_url1) { "http://#{domain}/" }
    let(:valid_url2) { "http://#{domain}" }
    let(:valid_url3) { "http://#{domain}/" }
    let(:valid_url4) { "http://#{domain}/docs/page1.html" }
    let(:valid_url5) { "http://#{domain}/docs" }
    let(:valid_url6) { "http://#{domain}/docs/" }
    let(:valid_url7) { "http://シラサギプロジェクト.jp" }
    let(:valid_url8) { "http://#{domain}/シラサギプロジェクト" }

    let(:valid_url9) { "https://#{domain}/" }
    let(:valid_url10) { "https://#{domain}" }
    let(:valid_url11) { "https://#{domain}/" }
    let(:valid_url12) { "https://#{domain}/docs/page1.html" }
    let(:valid_url13) { "https://#{domain}/docs" }
    let(:valid_url14) { "https://#{domain}/docs/" }
    let(:valid_url15) { "https://シラサギプロジェクト.jp" }
    let(:valid_url16) { "https://#{domain}/シラサギプロジェクト" }

    let(:invalid_url1) { "http://#{domain} /" }
    let(:invalid_url2) { "https://#{domain} /" }

    def build_page(url)
      build(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, link_url: url, link_label: "Link To")
        ]
      )
    end

    it "valid_url1" do
      item = build_page(valid_url1)
      expect(item.valid?).to be_truthy
    end

    it "valid_url2" do
      item = build_page(valid_url2)
      expect(item.valid?).to be_truthy
    end

    it "valid_url3" do
      item = build_page(valid_url3)
      expect(item.valid?).to be_truthy
    end

    it "valid_url4" do
      item = build_page(valid_url4)
      expect(item.valid?).to be_truthy

      expect(item.column_values.first.link_item_type).to eq article_page.collection_name.to_s
      expect(item.column_values.first.link_item_id).to eq article_page.id
    end

    it "valid_url5" do
      item = build_page(valid_url5)
      expect(item.valid?).to be_truthy

      expect(item.column_values.first.link_item_type).to eq article_node.collection_name.to_s
      expect(item.column_values.first.link_item_id).to eq article_node.id
    end

    it "valid_url6" do
      item = build_page(valid_url6)
      expect(item.valid?).to be_truthy

      expect(item.column_values.first.link_item_type).to eq article_node.collection_name.to_s
      expect(item.column_values.first.link_item_id).to eq article_node.id
    end

    it "valid_url7" do
      item = build_page(valid_url7)
      expect(item.valid?).to be_truthy
    end

    it "valid_url8" do
      item = build_page(valid_url8)
      expect(item.valid?).to be_truthy
    end

    it "valid_url9" do
      item = build_page(valid_url9)
      expect(item.valid?).to be_truthy
    end

    it "valid_url10" do
      item = build_page(valid_url10)
      expect(item.valid?).to be_truthy
    end

    it "valid_url11" do
      item = build_page(valid_url11)
      expect(item.valid?).to be_truthy
    end

    it "valid_url12" do
      item = build_page(valid_url12)
      expect(item.valid?).to be_truthy

      expect(item.column_values.first.link_item_type).to eq article_page.collection_name.to_s
      expect(item.column_values.first.link_item_id).to eq article_page.id
    end

    it "valid_url13" do
      item = build_page(valid_url13)
      expect(item.valid?).to be_truthy

      expect(item.column_values.first.link_item_type).to eq article_node.collection_name.to_s
      expect(item.column_values.first.link_item_id).to eq article_node.id
    end

    it "valid_url14" do
      item = build_page(valid_url14)
      expect(item.valid?).to be_truthy

      expect(item.column_values.first.link_item_type).to eq article_node.collection_name.to_s
      expect(item.column_values.first.link_item_id).to eq article_node.id
    end

    it "valid_url15" do
      item = build_page(valid_url15)
      expect(item.valid?).to be_truthy
    end

    it "valid_url16" do
      item = build_page(valid_url16)
      expect(item.valid?).to be_truthy
    end

    it "invalid_url1" do
      item = build_page(invalid_url1)
      expect(item.valid?).to be_falsey
    end

    it "invalid_url2" do
      item = build_page(invalid_url2)
      expect(item.valid?).to be_falsey
    end
  end
end
