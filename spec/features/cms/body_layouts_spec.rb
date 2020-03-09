require 'spec_helper'

describe "cms_body_layouts", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:item) { create(:cms_body_layout, site: site) }
  let(:index_path) { cms_body_layouts_path site.id }
  let(:new_path) { new_cms_body_layout_path site.id }
  let(:show_path) { cms_body_layout_path site.id, item }
  let(:edit_path) { edit_cms_body_layout_path site.id, item }
  let(:delete_path) { delete_cms_body_layout_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          expect(page).to have_no_selector('option', text: I18n.t('modules.addons.cms/body'))
          expect(page).to have_no_selector('option', text: I18n.t('modules.addons.cms/body_part'))
          expect(page).to have_no_selector('option', text: I18n.t('modules.addons.cms/form/page'))

          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[parts]", with: "part1"
          fill_in "item[html]", with: '<p class="yield0">{{ yield 0 }}</p>'
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#show" do
      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#edit" do
      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[parts]", with: "part1"
          fill_in "item[html]", with: '<p class="yield0">{{ yield 0 }}</p>'
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#delete" do
      it do
        visit delete_path
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end
  end
end
