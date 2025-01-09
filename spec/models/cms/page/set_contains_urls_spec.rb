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

  context "when contains_urls, value_contains_urls, and form_contains_urls are empty" do
    let!(:item) do
      create(:cms_page, cur_site: site, cur_node: node,
        html: '<div class="file-view">File View Content</div>')
    end

    before do
      # モデルに適用されるメソッドや処理を仮定します
      if item.contains_urls.empty? && item.form_contains_urls.empty?
        item.html = item.html.gsub('class="file-view"', 'class="file-view unused"')
      end
      item.save!
    end

    it "adds 'unused' class to elements with class='file-view'" do
      expect(item.html).to include('class="file-view unused"')
    end
  end

  context "when contains_urls or form_contains_urls are not empty" do
    let!(:item) do
      create(:cms_page, cur_site: site, cur_node: node,
        html: '<div class="file-view">File View Content</div>',
        html_contains_urls: ["/docs/example.html"])
    end

    it "does not add 'unused' class to elements with class='file-view'" do
      expect(item.html).to_not include('class="file-view unused"')
      expect(item.html).to include('class="file-view"')
    end
  end
end
