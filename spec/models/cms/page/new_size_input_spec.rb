require 'spec_helper'

describe Cms::Page, dbscope: :example do
  let(:node) { create :cms_node_page }

  describe ".new_size_input" do
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:file1) do
      SS::File.create_empty!(
        cur_user: cms_user, site_id: cms_site.id, model: "cms/page", filename: "logo.png", content_type: 'image/png'
      ) do |file|
        FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
      end
    end
    let!(:file2) do
      SS::File.create_empty!(
        cur_user: cms_user, site_id: cms_site.id, model: "cms/page", filename: "logo.png", content_type: 'image/png'
      ) do |file|
        FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
      end
    end
    let!(:column1) { create(:cms_column_free, cur_form: form, order: 1) }
    let!(:column2) { create(:cms_column_file_upload, cur_form: form, order: 1, file_type: 'image', html_tag: "a+img") }
    let!(:html_size) { html.bytesize }
    let!(:file_size1) { File.size(file1.path) }
    let!(:file_size2) { File.size(file2.path) }

    context "with html only" do
      let!(:html) { "<h1>SHIRASAGI</h1>" }
      let!(:item) { create :cms_page, cur_node: node, html: html }

      it do
        expect(item.size).to eq html_size
      end
    end

    context "with thumbnail only" do
      let!(:item) { create :cms_page, cur_node: node, thumb: file1 }
      it do
        expect(item.size).to eq file_size1
      end
    end

    context "with file only" do
      let!(:item) { create :cms_page, cur_node: node, file_ids: [file1.id] }
      it do
        expect(item.size).to eq file_size1
      end
    end

    context "with html and thumbnail and file" do
      let!(:html) { "<h1>SHIRASAGI</h1>" }
      let!(:item) { create :cms_page, cur_node: node, html: html, thumb: file1, file_ids: [file2.id] }

      it do
        expect(item.size).to eq html_size + file_size1 + file_size2
      end
    end
  end

end
