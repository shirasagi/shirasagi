require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

  describe ".new_size_input" do
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:file1) do
      SS::File.create_empty!(
        cur_user: cms_user, site_id: cms_site.id, model: "article/page", filename: "logo.png", content_type: 'image/png'
      ) do |file|
        FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
      end
    end
    let!(:file2) do
      SS::File.create_empty!(
        cur_user: cms_user, site_id: cms_site.id, model: "article/page", filename: "logo.png", content_type: 'image/png'
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
      let!(:item) { create :article_page, cur_node: node, html: html }

      it do
        expect(item.size).to eq html_size
      end
    end

    context "with block html only" do
      let!(:html) { item.try(:render_html).presence || item.try(:html) }
      let!(:item) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(column: column1, value: "<p>#{unique_id}</p><script>#{unique_id}</script>")
          ]
        )
      end
      it do
        expect(item.size).to eq html_size
      end
    end

    context "with thumbnail only" do
      let!(:item) { create :article_page, cur_node: node, thumb: file1 }
      it do
        expect(item.size).to eq file_size1
      end
    end

    context "with file only" do
      let!(:item) { create :article_page, cur_node: node, file_ids: [file1.id] }
      it do
        expect(item.size).to eq file_size1
      end
    end

    context "with block file only" do
      let!(:item) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            column2.value_type.new(
              column: column2, html_tag: column2.html_tag, file: file1,
              file_label: "<p>#{unique_id}</p><script>#{unique_id}</script>",
              text: Array.new(2) { "<p>#{unique_id}</p><script>#{unique_id}</script>" }.join("\n"),
              image_html_type: "thumb", link_url: "http://#{unique_id}.example.jp/"
            )
          ]
        )
      end
      let!(:value) { item.try(:render_html).presence || item.try(:html) }

      it do
        expect(item.size).to eq value.bytesize + file_size1
      end
    end

    context "with html and thumbnail and file" do
      let!(:html) { "<h1>SHIRASAGI</h1>" }
      let!(:item) { create :article_page, cur_node: node, html: html, thumb: file1, file_ids: [file2.id] }

      it do
        expect(item.size).to eq html_size + file_size1 + file_size2
      end
    end

    context "with block html and thumbnail and file" do
      let!(:item) do
        create(
          :article_page, cur_node: node, form: form, thumb: file1,
          column_values: [
            column2.value_type.new(
              column: column2, html_tag: column2.html_tag, file: file2,
              file_label: "<p>#{unique_id}</p><script>#{unique_id}</script>",
              text: Array.new(2) { "<p>#{unique_id}</p><script>#{unique_id}</script>" }.join("\n"),
              image_html_type: "thumb", link_url: "http://#{unique_id}.example.jp/"
            )
          ]
        )
      end
      let!(:value) { item.try(:render_html).presence || item.try(:html) }

      it do
        expect(item.size).to eq value.bytesize + file_size1 + file_size2
      end
    end
  end

end
