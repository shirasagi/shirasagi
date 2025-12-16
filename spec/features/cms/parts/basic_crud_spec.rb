require 'spec_helper'

describe "cms_parts", type: :feature, js: true do
  subject(:site) { cms_site }
  subject(:item) { Cms::Part.last }
  subject(:index_path) { cms_parts_path site.id }
  subject(:new_path) { new_cms_part_path site.id }
  subject(:show_path) { cms_part_path site.id, item }
  subject(:edit_path) { edit_cms_part_path site.id, item }
  subject(:delete_path) { delete_cms_part_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      # it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      # 正常に新規作成できたことを確認
      wait_for_notice I18n.t("ss.notice.saved")
      expect(page).to have_content("sample")
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")

      # it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
      # 詳細画面にパーツ名が表示されていることを確認
      expect(page).to have_content(item.name)

      # it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")

      # it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
      expect(current_path).to eq index_path
    end

    context 'with descendant part' do
      let(:node) { create :cms_node }
      let!(:item) { create :cms_part, filename: "#{node.filename}/name" }

      it "#index" do
        visit index_path
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_selector('li.list-item', count: 0)

        select I18n.t('cms.options.node_target.descendant'), from: 's[target]'
        click_on I18n.t('ss.buttons.search')
        expect(page).to have_selector('li.list-item', count: 1)

        click_link item.name
        expect(current_path).not_to eq show_path
        expect(current_path).to eq node_part_path(site: site.id, cid: node.id, id: item.id)
      end
    end
  end
end
