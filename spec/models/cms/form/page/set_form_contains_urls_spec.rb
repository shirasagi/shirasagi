require 'spec_helper'

describe Cms::Addon::Form::Page, dbscope: :example do
  let(:node) { create :cms_node_page }

  describe ".set_form_contains_urls" do
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }

    context "with Cms::Column::Value::Free" do
      let!(:html) { "<p><a href=\"/docs/page1.html\">関連記事リンク1</a></p>\r\n<p><a href=\"/docs/page2.html\">関連記事リンク2</a></p>" }
      let!(:column1) { create(:cms_column_free, cur_site: cms_site, cur_form: form, order: 1) }
      let!(:form_column1) { column1.value_type.new(column: column1, value: html) }
      let!(:page) { create :cms_page, cur_node: node, column_values: [form_column1] }

      it do
        expect(page.contains_urls).to eq []
        expect(page.form_contains_urls).to eq ["/docs/page1.html", "/docs/page2.html"]
      end
    end

    context "with Cms::Column::Value::UrlField" do
      # create(:cms_column_url_field, cur_site: cms_site, cur_form: form, order: 1, html_tag: '')
      let!(:column1) { create(:cms_column_url_field, cur_site: cms_site, cur_form: form, order: 1, html_tag: 'a') }
      let(:url1) { "/#{unique_id}/" }
      let!(:form_column1) { column1.value_type.new(column: column1, value: "外部リンク,#{url1}") }
      let!(:column2) { create(:cms_column_url_field, cur_site: cms_site, cur_form: form, order: 2, html_tag: 'a') }
      let(:url2) { "/docs/page3.html" }
      let!(:form_column2) { column2.value_type.new(column: column2, value: "関連記事リンク3,#{url2}") }
      let!(:page) { create :cms_page, cur_node: node, column_values: [form_column1, form_column2] }

      it do
        expect(page.contains_urls).to eq []
        expect(page.form_contains_urls).to eq [url1, url2]
      end
    end

    context "with Cms::Column::Value::UrlField2" do
      let!(:column1) { create(:cms_column_url_field2, cur_site: cms_site, cur_form: form, order: 1) }
      let(:url1) { "/#{unique_id}/" }
      let!(:form_column1) { column1.value_type.new(column: column1, link_url: url1, link_label: "外部リンク") }
      let!(:column2) { create(:cms_column_url_field2, cur_site: cms_site, cur_form: form, order: 2) }
      let(:url2) { "/docs/page4.html" }
      let!(:form_column2) { column2.value_type.new(column: column2, link_url: url2, link_label: "関連記事リンク4") }
      let!(:page) { create :cms_page, cur_node: node, column_values: [form_column1, form_column2] }

      it do
        expect(page.contains_urls).to eq []
        expect(page.form_contains_urls).to eq [url1, url2]
      end
    end

    context "with Cms::Column::Value::Free and Cms::Column::Value::UrlField and Cms::Column::Value::UrlField2" do
      let!(:html) { "<p><a href=\"/docs/page1.html\">関連記事リンク1</a></p>\r\n<p><a href=\"/docs/page2.html\">関連記事リンク2</a></p>" }
      let!(:column1) { create(:cms_column_free, cur_site: cms_site, cur_form: form, order: 1) }
      let!(:form_column1) { column1.value_type.new(column: column1, value: html) }

      let!(:column2) { create(:cms_column_url_field, cur_site: cms_site, cur_form: form, order: 2, html_tag: 'a') }
      let(:url1) { "/#{unique_id}/" }
      let!(:form_column2) { column2.value_type.new(column: column2, value: "外部リンク,#{url1}") }
      let!(:column3) { create(:cms_column_url_field, cur_site: cms_site, cur_form: form, order: 3, html_tag: 'a') }
      let(:url2) { "/docs/page3.html" }
      let!(:form_column3) { column3.value_type.new(column: column3, value: "関連記事リンク3,#{url2}") }

      let!(:column4) { create(:cms_column_url_field2, cur_site: cms_site, cur_form: form, order: 4) }
      let(:url3) { "/#{unique_id}/" }
      let!(:form_column4) { column4.value_type.new(column: column4, link_url: url3, link_label: "外部リンク") }
      let!(:column5) { create(:cms_column_url_field2, cur_site: cms_site, cur_form: form, order: 5) }
      let(:url4) { "/docs/page4.html" }
      let!(:form_column5) { column5.value_type.new(column: column5, link_url: url4, link_label: "関連記事リンク4") }

      let!(:page) do
        create :cms_page, cur_node: node,
        column_values: [form_column1, form_column2, form_column3, form_column4, form_column5]
      end

      it do
        expect(page.contains_urls).to eq []
        expect(page.form_contains_urls).to eq ["/docs/page1.html", "/docs/page2.html", url1, url2, url3, url4]
      end
    end

    context "with html" do
      let!(:html) { "<p><a href=\"/docs/page1.html\">関連記事リンク1</a></p>\r\n<p><a href=\"/docs/page2.html\">関連記事リンク2</a></p>" }
      let!(:page) { create :cms_page, cur_node: node, html: html }
      it do
        expect(page.contains_urls).to eq ["/docs/page1.html", "/docs/page2.html"]
        expect(page.form_contains_urls).to eq []
      end
    end

    context "with related_page" do
      let!(:related_page) { create(:article_page, site: cms_site, filename: "docs/page27.html", name: "関連ページ") }
      let!(:page) { create :cms_page, cur_node: node, related_page_ids: [related_page.id] }
      it do
        expect(page.contains_urls).to eq []
        expect(page.form_contains_urls).to eq []
      end
    end
  end
end
