require 'spec_helper'

describe "gws_affair_duty_notices", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }
    let(:item) { create(:gws_affair_duty_notice) }
    let(:index_path) { gws_affair_duty_notices_path site.id }
    let(:new_path) { new_gws_affair_duty_notice_path site.id }
    let(:show_path) { gws_affair_duty_notice_path site.id, item }
    let(:edit_path) { edit_gws_affair_duty_notice_path site.id, item }
    let(:delete_path) { delete_gws_affair_duty_notice_path site.id, item }

    context "basic crud" do
      before { login_gws_user }

      it "#index" do
        visit index_path
        expect(current_path).not_to eq sns_login_path
      end

      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          select I18n.t("gws/affair.options.notice_type.month_time_limit"), from: "item[notice_type]"
          fill_in "item[threshold_hour]", with: 60
          fill_in "item[body]", with: "body"
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      end

      it "#show" do
        visit show_path
        expect(page).to have_css("#addon-basic", text: item.name)
      end

      it "#edit" do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      end

      it "#delete" do
        visit delete_path
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end
    end
  end
end
