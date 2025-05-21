require 'spec_helper'

describe "cms_parts", type: :feature do
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
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t('ss.buttons.save')
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
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

  context "with accessibility error and permissions" do
    let!(:site) { cms_site }
    let!(:admin) { cms_user }
    let(:layout_permissions) do
      %w(
        read_private_cms_parts edit_private_cms_parts delete_private_cms_parts
        read_other_cms_parts edit_other_cms_parts delete_other_cms_parts
        edit_cms_ignore_syntax_check
      )
    end
    let!(:role) do
      create :cms_role, cur_site: site, name: "role-#{unique_id}", permissions: layout_permissions
    end
    let(:user) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: role.id }
    let(:html_with_error) { '<iframe src="https://example.com"></iframe>' }

    before { login_user user }

    it "shows accessibility error and allows ignore if permitted" do
      visit new_cms_part_path(site: site)
      within "form#item-form" do
        fill_in "item[name]", with: "アクセシビリティテスト"
        fill_in "item[basename]", with: "a11y-test"
        fill_in_code_mirror "item[html]", with: html_with_error
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css(".error", text: "title属性を設定してください")
      # 権限があれば「警告を無視して保存」ボタンが表示される
      expect(page).to have_button(I18n.t("ss.buttons.ignore_syntax_check"))
      click_button I18n.t("ss.buttons.ignore_syntax_check")
      expect(page).to have_no_css("form#item-form")
      expect(Cms::Part.where(name: "アクセシビリティテスト").count).to eq 1
    end

    it "auto correct removes error" do
      visit new_cms_part_path(site: site)
      within "form#item-form" do
        fill_in "item[name]", with: "自動修正テスト"
        fill_in "item[basename]", with: "auto-correct-test"
        fill_in_code_mirror "item[html]", with: html_with_error
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css(".error", text: "title属性を設定してください")
      expect(page).to have_button(I18n.t("ss.buttons.auto_correct"))
      click_button I18n.t("ss.buttons.auto_correct")
      # 自動修正後にエラーが消えることを確認
      expect(page).to have_no_css(".error", text: "title属性を設定してください")
    end
  end

  context "with accessibility error and no ignore permission" do
    let!(:site) { cms_site }
    let!(:admin) { cms_user }
    let(:layout_permissions) do
      %w(
        read_private_cms_parts edit_private_cms_parts delete_private_cms_parts
        read_other_cms_parts edit_other_cms_parts delete_other_cms_parts
      )
    end
    let!(:role) do
      create :cms_role, cur_site: site, name: "role-#{unique_id}", permissions: layout_permissions
    end
    let(:user) { create :cms_test_user, group_ids: admin.group_ids, cms_role_ids: role.id }
    let(:html_with_error) { '<iframe src="https://example.com"></iframe>' }

    before { login_user user }

    it "shows accessibility error and does not allow ignore" do
      visit new_cms_part_path(site: site)
      within "form#item-form" do
        fill_in "item[name]", with: "アクセシビリティテスト"
        fill_in "item[basename]", with: "a11y-test"
        fill_in_code_mirror "item[html]", with: html_with_error
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css(".error", text: "title属性を設定してください")
      # 権限がなければ「警告を無視して保存」ボタンが表示されない
      expect(page).to have_no_button(I18n.t("ss.buttons.ignore_syntax_check"))
    end
  end
end
