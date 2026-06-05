require 'spec_helper'

describe Cms::Column::Value::MultipleFilesUpload, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }

  shared_examples "header persistence" do |header_text|
    it "persists the header text alongside file_ids" do
      page.reload
      value = page.column_values.first
      expect(value.header).to eq header_text
      expect(value.file_ids.length).to eq 1
    end

    it "includes the header in history_summary" do
      page.reload
      value = page.column_values.first
      expect(value.history_summary).to include(header_text)
    end

    it "matches header in search_values" do
      page.reload
      value = page.column_values.first
      expect(value.search_values([header_text])).to be_truthy
    end
  end

  context "when column.file_type is image" do
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: form, order: 1, file_type: "image") }
    let!(:file) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let(:header_text) { "詳細については下記の画像をご覧ください。" }
    let(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column.value_type.new(
            column: column,
            file_ids: [file.id.to_s],
            header: header_text
          )
        ]
      )
    end

    include_examples "header persistence", "詳細については下記の画像をご覧ください。"

    it "accepts non-image files for image file_type" do
      pdf = tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
      article_page = build(
        :article_page, cur_node: node, form: form,
        column_values: [
          column.value_type.new(column: column, file_ids: [pdf.id.to_s])
        ]
      )
      expect(article_page).to be_valid
    end

    it "renders images-header and column2 in to_default_html" do
      page.reload
      value = page.column_values.first
      html = value.to_default_html
      expect(html).to include('class="images"')
      expect(html).to include('class="images-header"')
      expect(html).to include('class="column2"')
    end
  end

  context "when column.file_type is attachment" do
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: form, order: 1, file_type: "attachment") }
    let!(:file) do
      tmp_ss_file(
        Cms::File,
        contents: "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf",
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end
    let(:header_text) { "詳細については下記の資料をご確認ください。" }
    let(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column.value_type.new(
            column: column,
            file_ids: [file.id.to_s],
            file_labels: { file.id.to_s => "資料PDF" },
            header: header_text
          )
        ]
      )
    end

    include_examples "header persistence", "詳細については下記の資料をご確認ください。"

    it "accepts non-image files for attachment file_type" do
      article_page = build(
        :article_page, cur_node: node, form: form,
        column_values: [
          column.value_type.new(column: column, file_ids: [file.id.to_s])
        ]
      )
      expect(article_page).to be_valid
    end

    it "renders attachment-header and attachment-list in to_default_html" do
      page.reload
      value = page.column_values.first
      html = value.to_default_html
      expect(html).to include('class="attachments"')
      expect(html).to include('class="attachment-header"')
      expect(html).to include('class="attachment-list"')
    end
  end

  describe "#before_save_files" do
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: form, order: 1, file_type: "image") }

    context "with an unowned cms/file (clone required)" do
      let!(:file) do
        tmp_ss_file(
          Cms::File,
          contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
          site: site, user: cms_user, model: Cms::File::FILE_MODEL
        )
      end

      let(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            column.value_type.new(
              column: column,
              file_ids: [file.id.to_s],
              file_labels: { file.id.to_s => "custom-label" }
            )
          ]
        )
      end

      it "persists file_ids pointing to the cloned file, and does not leak the page as owner of the original" do
        page.reload
        value = page.column_values.first

        expect(value.file_ids.length).to eq 1
        cloned_id = value.file_ids.first
        expect(cloned_id).not_to eq file.id.to_s

        cloned_file = SS::File.find(cloned_id)
        expect(cloned_file.owner_item_id).to eq page.id
        expect(cloned_file.owner_item_type).to eq page.class.name

        file.reload
        expect(file.owner_item_id).to be_blank
        expect(file.owner_item_type).to be_blank

        expect(value.file_labels[cloned_id]).to eq "custom-label"
        expect(value.file_labels).not_to have_key(file.id.to_s)
      end
    end

    context "with a file already owned by the page (no clone)" do
      let!(:file) do
        tmp_ss_file(
          Cms::File,
          contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
          site: site, user: cms_user, model: Cms::File::FILE_MODEL
        )
      end

      let!(:page) do
        create(
          :article_page, cur_node: node, form: form,
          column_values: [
            column.value_type.new(column: column, file_ids: [file.id.to_s])
          ]
        )
      end

      it "keeps file_ids stable on re-save" do
        page.reload
        value = page.column_values.first
        first_save_ids = value.file_ids.dup

        page.update(name: "renamed-#{unique_id}")
        page.reload
        value = page.column_values.first

        expect(value.file_ids).to eq first_save_ids
      end
    end
  end
end
