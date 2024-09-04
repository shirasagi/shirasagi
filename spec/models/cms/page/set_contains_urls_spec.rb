require 'spec_helper'

describe Cms::Page, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :cms_node_page }

  context "default form (Cms::Addon::Body)" do
    let!(:item) do
      create(:cms_page, cur_site: site, cur_node: node,
        html: "<a href=\"#{file.url}\">link</a>", file_ids: [file.id])
    end
    let!(:file) { create :ss_file, site: site }

    it do
      expect(item.contains_urls).to eq [file.url]
      expect(item.form_contains_urls).to eq []
    end
  end

  context "cms_form (Cms::Form)" do
    let!(:item) do
      create(:cms_page, cur_site: site, cur_node: node,
        form: form, column_values: column_values)
    end
    let!(:file) { create :ss_file, site: site }

    let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
    let!(:column1) { create :cms_column_free, cur_site: site, cur_form: form }
    let(:column_values) do
      [
        column1.value_type.new(column: column1, value: "<a href=\"#{file.url}\">link</a>", file_ids: [file.id])
      ]
    end

    it do
      expect(item.contains_urls).to eq []
      expect(item.column_values.first.contains_urls).to eq [file.url]
      expect(item.form_contains_urls).to eq [file.url]
    end
  end

  context "default form to cms_form" do
    let!(:item) do
      create(:cms_page, cur_site: site, cur_node: node,
        html: "<a href=\"#{file1.url}\">link</a>", file_ids: [file1.id])
    end
    let!(:file1) { create :ss_file, site: site }

    let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry' }
    let!(:column1) { create :cms_column_free, cur_site: site, cur_form: form }
    let(:column_values) do
      [
        column1.value_type.new(column: column1, value: "<a href=\"#{file2.url}\">link</a>", file_ids: [file2.id])
      ]
    end
    let(:file2) { create :ss_file, site: site }

    it do
      expect(item.contains_urls).to eq [file1.url]
      expect(item.form_contains_urls).to eq []

      item.form = form
      item.column_values = column_values
      item.update!

      expect(item.contains_urls).to eq [file1.url]
      expect(item.column_values.first.contains_urls).to eq [file2.url]
      expect(item.form_contains_urls).to eq [file2.url]
    end
  end
end
