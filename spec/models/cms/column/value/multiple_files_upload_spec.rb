require 'spec_helper'

describe Cms::Column::Value::MultipleFilesUpload, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:column) { create(:cms_column_multiple_files_upload, cur_form: form, order: 1) }

  describe "#before_save_files" do
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

        # clone を上書き消失させていないこと（= 旧バグの再発防止）
        expect(cloned_id).not_to eq file.id.to_s

        cloned_file = SS::File.find(cloned_id)
        expect(cloned_file.owner_item_id).to eq page.id
        expect(cloned_file.owner_item_type).to eq page.class.name

        # 元のファイルに所有権が書き込まれていないこと（共有元汚染防止）
        file.reload
        expect(file.owner_item_id).to be_blank
        expect(file.owner_item_type).to be_blank

        # file_labels のキーもクローン後 id に移行していること
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
