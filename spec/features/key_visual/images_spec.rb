require 'spec_helper'

describe "key_visual_images", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :key_visual_node_image, name: "key_visual" }
  let!(:item) { create :key_visual_image }
  let(:index_path) { key_visual_images_path site.id, node }
  let(:show_path) { key_visual_image_path site.id, node, item }
  let(:edit_path) { edit_key_visual_image_path site.id, node, item }

  context "with auth" do
    let!(:file) do
      tmp_ss_file(
        Cms::TempFile, user: cms_user, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:name) { "sample" }
    let(:name2) { "modify" }
    let(:remark_html) { unique_id }
    let(:remark_html2) { unique_id }

    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      SS.config.replace_value_at(:env, :max_filesize_ext, {})

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[link_url]", with: "http://example.jp"
        fill_in_code_mirror "item[remark_html]", with: remark_html
        attach_to_ss_file_field "item[file_id]", file

        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit index_path
      click_on name
      expect(page).to have_css("#addon-basic", text: name)
      expect(page).to have_css("#addon-basic", text: remark_html)

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        fill_in_code_mirror "item[remark_html]", with: remark_html2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_css("#addon-basic", text: name2)
      expect(page).to have_css("#addon-basic", text: remark_html2)

      visit index_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end

    it "#edit" do
      visit edit_path
      expect(item.display_remarks).to be_blank

      within "form#item-form" do
        first('[name="item[display_remarks][]"][value="title"]').check
        first('[name="item[display_remarks][]"][value="remark_html"]').check
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.display_remarks).to match_array %w(title remark_html)

      visit edit_path
      within "form#item-form" do
        first('[name="item[display_remarks][]"][value="title"]').uncheck
        first('[name="item[display_remarks][]"][value="remark_html"]').uncheck
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.display_remarks).to be_blank
    end
  end
end
