require 'spec_helper'

describe "cms/line/deliver_conditions", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:item) { create(:cms_line_deliver_condition, deliver_category_ids: [deliver_category_first1.id]) }
  let(:name) { unique_id }

  let!(:deliver_category_first) do
    create(:cms_line_deliver_category_category, filename: "c1", select_type: "checkbox")
  end
  let!(:deliver_category_first1) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_first, filename: "1")
  end
  let!(:deliver_category_first2) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_first, filename: "2")
  end
  let!(:deliver_category_first3) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_first, filename: "3")
  end
  let!(:deliver_category_second) do
    create(:cms_line_deliver_category_category, filename: "c2", select_type: "checkbox")
  end
  let!(:deliver_category_second1) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_second, filename: "1")
  end
  let!(:deliver_category_second2) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_second, filename: "2")
  end
  let!(:deliver_category_second3) do
    create(:cms_line_deliver_category_selection, parent: deliver_category_second, filename: "3")
  end

  let(:index_path) { cms_line_deliver_conditions_path site }
  let(:new_path) { new_cms_line_deliver_condition_path site }
  let(:show_path) { cms_line_deliver_condition_path site, item }
  let(:edit_path) { edit_cms_line_deliver_condition_path site, item }
  let(:delete_path) { delete_cms_line_deliver_condition_path site, item }

  describe "basic crud" do
    before { login_cms_user }

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: name
        find("input[name='item[deliver_category_ids][]'][value='#{deliver_category_first1.id}']").set(true)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#addon-basic", text: name)
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        find("input[name='item[deliver_category_ids][]'][value='#{deliver_category_first2.id}']").set(true)
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end
  end
end
