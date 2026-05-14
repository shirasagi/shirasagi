require 'spec_helper'
require 'fileutils'

# 差し替えダイアログ経由（name 未変更・同拡張子）の差し替えを行ったあと、
# 公開ファイルコピーが新しい画像の内容に置き換わることを検証する E2E。
#
# MultipleImagesUpload も MultipleAttachmentsUpload と同じく、
# - _column_show.html.erb に差し替えボタンが無い → ボタンクリック自体ができない
# - SS::ReplaceFile#update_owner_page が Free 以外のカラム経由のファイルを
#   再生成しない → 公開コピーが更新されない
# という２つの問題を抱える。本 spec はその両方を回帰テストとしてカバーする。
describe "article_pages MultipleImagesUpload replace file", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create :article_node_page, filename: "docs", name: "article",
           layout_id: layout.id, group_ids: [cms_group.id]
  end
  let!(:form) do
    create(:cms_form, cur_site: site, state: 'public', sub_type: 'static', group_ids: [cms_group.id])
  end
  let!(:column) { create(:cms_column_multiple_images_upload, cur_form: form, order: 1) }

  let(:before_image) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let(:after_image) { "#{Rails.root}/spec/fixtures/webapi/replace.png" }

  let!(:initial_file) do
    tmp_ss_file(
      Cms::File,
      contents: before_image,
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
          file_labels: { initial_file.id.to_s => "logo alt" }
        )
      ]
    )
  end

  let(:show_path) { article_page_path site.id, node, item }

  before { login_cms_user }

  it "regenerates the public file copy after replace via the dialog without changing the name" do
    item.generate_file

    cloned_file = item.reload.column_values.first.files.first
    public_path = "#{cloned_file.public_dir}/#{cloned_file.filename}"
    expect(File.exist?(public_path)).to be true
    expect(File.size(public_path)).to eq File.size(before_image)

    visit show_path

    within ".column-value-cms-column-multipleimagesupload" do
      expect(page).to have_css('.file-view', text: cloned_file.name)
      wait_for_cbox_opened do
        click_on I18n.t("ss.buttons.replace_file")
      end
    end

    within_cbox do
      expect(page).to have_css('.tab-name', text: I18n.t("ss.buttons.replace_file"))
      wait_for_js_ready

      attach_file "item[in_file]", after_image
      click_button I18n.t('inquiry.confirm')

      expect(page).to have_css('.file-view.before')
      expect(page).to have_css('.file-view.after')

      # name は変更しない（rename_file → remove_public_file 経由ではなく、
      # update_owner_page 内の再生成パスをテストするため）
      click_button I18n.t('ss.buttons.replace_save')
    end
    wait_for_notice I18n.t('ss.notice.replace_saved')

    expect(File.size(public_path)).to eq File.size(after_image)
  end
end
