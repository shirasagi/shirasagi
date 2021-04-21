require 'spec_helper'

describe "sys_groups", type: :feature, dbscope: :example do
  let(:item) { create(:sys_group) }
  let(:index_path) { sys_groups_path }
  let(:new_path) { new_sys_group_path }
  let(:show_path) { sys_group_path item }
  let(:edit_path) { edit_sys_group_path item }
  let(:delete_path) { delete_sys_group_path item }

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_sys_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
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
  end

  context "gws_use" do
    before { login_sys_user }

    context "on root group" do
      let(:name) { unique_id }

      it do
        visit index_path
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          expect(page).to have_no_css("select[name='item[gws_use]']")

          fill_in "item[name]", with: name
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        click_on name
        click_on I18n.t("ss.links.edit")
        within "form#item-form" do
          expect(page).to have_css("select[name='item[gws_use]']")

          select I18n.t("ss.options.gws_use.enabled"), from: "item[gws_use]"
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      end
    end

    context "on child group" do
      let(:name) { "#{item.name}/#{unique_id}" }

      it do
        # ensure that item is created
        item

        visit index_path
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          expect(page).to have_no_css("select[name='item[gws_use]']")

          fill_in "item[name]", with: name
          click_on I18n.t('ss.buttons.save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        visit index_path
        click_on name
        click_on I18n.t("ss.links.edit")
        expect(page).to have_no_css("select[name='item[gws_use]']")
      end
    end
  end
end
