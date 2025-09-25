require 'spec_helper'

describe "cms_syntax_checker_setting", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }

  context "basic crud" do
    let(:syntax_check) { %w(enabled disabled).sample }
    let(:syntax_check_label) { I18n.t("ss.options.state.#{syntax_check}") }
    let(:syntax_checker_link_text_min_length) { rand(0..10) }
    let(:syntax_check2) { %w(enabled disabled).sample }
    let(:syntax_check2_label) { I18n.t("ss.options.state.#{syntax_check2}") }
    let(:syntax_checker_link_text_min_length2) { rand(0..10) }

    it do
      login_cms_user to: cms_syntax_checker_main_path(site: site)
      click_on I18n.t("ss.config")
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        select syntax_check_label, from: "item[syntax_check]"
        fill_in "item[syntax_checker_link_text_min_length]", with: syntax_checker_link_text_min_length

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Site.find(site.id).tap do |item|
        expect(item.syntax_check).to eq syntax_check
        expect(item.syntax_checker_link_text_min_length).to eq syntax_checker_link_text_min_length
      end

      visit cms_syntax_checker_main_path(site: site)
      click_on I18n.t("ss.config")
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        select syntax_check2_label, from: "item[syntax_check]"
        fill_in "item[syntax_checker_link_text_min_length]", with: syntax_checker_link_text_min_length2

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      Cms::Site.find(site.id).tap do |item|
        expect(item.syntax_check).to eq syntax_check2
        expect(item.syntax_checker_link_text_min_length).to eq syntax_checker_link_text_min_length2
      end
    end
  end
end
