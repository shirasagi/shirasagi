require 'spec_helper'

describe "cms_sites", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { cms_site_path site.id }

  context "basic crud" do
    before { login_cms_user }

    it do
      visit index_path
      expect(status_code).to eq 200

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      site.reload
      expect(site.name).to eq "modify"
    end
  end

  context "approve_setting" do
    let(:forced_update) { %w(enabled disabled).sample }
    let(:forced_update_label) { I18n.t("ss.options.state.#{forced_update}") }
    let(:close_confirmation) { %w(enabled disabled).sample }
    let(:close_confirmation_label) { I18n.t("ss.options.state.#{close_confirmation}") }
    let(:approve_remind_state) { %w(enabled disabled).sample }
    let(:approve_remind_state_label) { I18n.t("ss.options.state.#{approve_remind_state}") }
    let(:approve_remind_later) { %w(1.day 2.days 3.days 4.days 5.days 6.days 1.week 2.weeks).sample }
    let(:approve_remind_state_label) { I18n.t("ss.options.approve_remind_state.#{approve_remind_later}") }

    it do
      visit index_path
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        select forced_update_label, from: "s[forced_update]"
        select close_confirmation_label, from: "s[close_confirmation]"
        select approve_remind_state_label, from: "s[approve_remind_state]"
        select approve_remind_later_label, from: "s[approve_remind_later]"

        click_on I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      site.reload
      expect(site.forced_update).to eq forced_update
      expect(site.close_confirmation).to eq close_confirmation
      expect(site.approve_remind_state).to eq approve_remind_state
      expect(site.approve_remind_later).to eq approve_remind_later
    end
  end
end
