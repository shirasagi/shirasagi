require 'spec_helper'

describe "cms_layouts", type: :feature do
  subject(:site) { cms_site }
  subject(:item) { Cms::Layout.last }
  subject(:index_path) { cms_layouts_path site.id }
  subject(:new_path) { new_cms_layout_path site.id }
  subject(:show_path) { cms_layout_path site.id, item }
  subject(:edit_path) { edit_cms_layout_path site.id, item }
  subject(:delete_path) { delete_cms_layout_path site.id, item }

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

    context 'with descendant layout' do
      let(:node) { create :cms_node }
      let!(:item) { create :cms_layout, filename: "#{node.filename}/name" }

      it "#index" do
        visit index_path
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_selector('li.list-item', count: 0)

        select I18n.t('cms.options.node_target.descendant'), from: 's[target]'
        click_on I18n.t('ss.buttons.search')
        expect(page).to have_selector('li.list-item', count: 1)

        click_link item.name
        expect(current_path).not_to eq show_path
        expect(current_path).to eq node_layout_path(site: site.id, cid: node.id, id: item.id)
      end
    end
  end
end
