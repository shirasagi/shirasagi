require 'spec_helper'

describe "cms/line/deliver_category", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:parent) { create :cms_line_deliver_category_category }
  let(:item) { create :cms_line_deliver_category_category, parent: parent }
  let(:name) { unique_id }

  let(:index_path) { cms_line_deliver_category_categories_path site, parent }
  let(:new_path) { new_cms_line_deliver_category_category_path site, parent }
  let(:show_path) { cms_line_deliver_category_category_path site, parent, item }
  let(:edit_path) { edit_cms_line_deliver_category_category_path site, parent, item }
  let(:delete_path) { delete_cms_line_deliver_category_category_path site, parent, item }

  def root_categories
    Cms::Line::DeliverCategory::Category.site(site).and_root
  end

  def child_categories
    parent.reload
    parent.children
  end

  describe "basic crud" do
    before { login_cms_user }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("#addon-basic", text: name)
      expect(root_categories.size).to eq 1
      expect(child_categories.size).to eq 1
      expect(child_categories.first.name).to eq name
      expect(child_categories.first.depth).to eq 2
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
      expect(root_categories.size).to eq 1
      expect(child_categories.size).to eq 1
      expect(child_categories.first.name).to eq item.name
      expect(child_categories.first.depth).to eq 2
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("#addon-basic", text: "modify")
      expect(root_categories.size).to eq 1
      expect(child_categories.size).to eq 1
      expect(child_categories.first.name).to eq "modify"
      expect(child_categories.first.depth).to eq 2
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(root_categories.size).to eq 1
      expect(child_categories.size).to eq 0
    end
  end
end
