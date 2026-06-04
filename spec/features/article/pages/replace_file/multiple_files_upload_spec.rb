require 'spec_helper'
require 'fileutils'

# 差し替えダイアログ経由の差し替え後、公開コピーが新しいファイルの内容に置き換わることを検証する E2E。
# 統合された MultipleFilesUpload で file_type に依存せずに同じ挙動になることを保証する。
describe "article_pages MultipleFilesUpload replace file", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create :article_node_page, filename: "docs", name: "article",
           layout_id: layout.id, group_ids: [cms_group.id]
  end
  let!(:form) do
    create(:cms_form, cur_site: site, state: 'public', sub_type: 'static', group_ids: [cms_group.id])
  end

  before { login_cms_user }

  shared_examples "replace public file copy" do |file_type:, before_fixture:, after_fixture:|
    let!(:column) { create(:cms_column_multiple_files_upload, cur_form: form, order: 1, file_type: file_type) }
    let(:before_path) { "#{Rails.root}/spec/fixtures/#{before_fixture}" }
    let(:after_path) { "#{Rails.root}/spec/fixtures/#{after_fixture}" }

    let!(:initial_file) do
      tmp_ss_file(
        Cms::File,
        contents: before_path,
        site: site, user: cms_user, model: Cms::File::FILE_MODEL
      )
    end

    let!(:item) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: form,
        group_ids: [cms_group.id],
        state: 'public',
        column_values: [
          column.value_type.new(
            column: column,
            file_ids: [initial_file.id.to_s],
            file_labels: { initial_file.id.to_s => "label" }
          )
        ]
      )
    end

    it "regenerates the public file copy after replace" do
      item.generate_file

      cloned_file = item.reload.column_values.first.files.first
      public_path = "#{cloned_file.public_dir}/#{cloned_file.filename}"
      expect(File.exist?(public_path)).to be true
      expect(File.size(public_path)).to eq File.size(before_path)

      visit article_page_path(site.id, node, item)

      within ".column-value-cms-column-multiplefilesupload" do
        expect(page).to have_css('.file-view', text: cloned_file.name)
        wait_for_cbox_opened do
          click_on I18n.t("ss.buttons.replace_file")
        end
      end

      within_cbox do
        expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.replace_file"))
        wait_for_js_ready

        attach_file "item[in_file]", after_path
        click_button I18n.t('inquiry.confirm')

        expect(page).to have_css('.file-view.before')
        expect(page).to have_css('.file-view.after')

        click_button I18n.t('ss.buttons.replace_save')
      end
      wait_for_notice I18n.t('ss.notice.replace_saved')

      expect(File.size(public_path)).to eq File.size(after_path)
    end
  end

  context "with image file_type" do
    include_examples "replace public file copy", file_type: "image",
      before_fixture: "ss/logo.png", after_fixture: "webapi/replace.png"
  end

  context "with attachment file_type" do
    include_examples "replace public file copy", file_type: "attachment",
      before_fixture: "ss/shirasagi.pdf", after_fixture: "opendata/resource.pdf"
  end
end
