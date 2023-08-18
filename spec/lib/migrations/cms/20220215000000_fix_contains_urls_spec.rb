require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20220215000000_fix_contains_urls.rb")

RSpec.describe SS::Migration20220215000000, dbscope: :example do
  context "with html page" do
    let(:url) { unique_id }
    let(:html) { "<a href=\" #{url} \">#{url}</a>" }
    let(:page) { create :cms_page, html: html }

    before do
      page.set(contains_urls: [ " #{url} " ])
      described_class.new.change
      page.reload
    end

    it do
      expect(page.contains_urls).to eq [url]
    end
  end

  context "with form page" do
    let(:site) { cms_site }
    let(:node) { create :article_node_page, cur_site: site }

    let(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry', html: nil }
    let(:column1) do
      create(:cms_column_free, cur_site: site, name: "column1", cur_form: form, required: 'optional', order: 1)
    end
    let(:column2) do
      create(:cms_column_url_field, cur_site: site, name: "column2", cur_form: form, required: 'optional', order: 2)
    end
    let(:column3) do
      create(:cms_column_url_field2, cur_site: site, name: "column2", cur_form: form, required: 'optional', order: 3)
    end
    let(:column4) do
      create(
        :cms_column_file_upload, cur_site: site, name: "column2", cur_form: form, required: 'optional', order: 4,
        file_type: 'banner'
      )
    end
    let(:column_values) do
      [
        column1.value_type.new(column: column1, value: "<a href=\" value1 \">value1</a>"),
        column2.value_type.new(column: column2, value: " value2 , value2 "),
        column3.value_type.new(column: column3, link_url: " value3 "),
        column4.value_type.new(column: column4, link_url: " value4 ")
      ]
    end
    let(:page) { create :article_page, cur_site: site, cur_node: node, form: form, column_values: column_values }

    before do
      page.set(form_contains_urls: [" value1 ", " value2 ", " value3 ", " value4 "], value_contains_urls: [" value1 "])
      page.column_values.first.set(contains_urls: [" value1 "])
      described_class.new.change
      page.reload
    end

    it do
      expect(page.form_contains_urls).to eq %w(value1 value2 value3 value4)
      expect(page.value_contains_urls).to eq %w(value1)
      expect(page.column_values.first.contains_urls).to eq %w(value1)
    end
  end
end
