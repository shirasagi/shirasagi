require 'spec_helper'

describe "gws_sites", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:workflow_new_days) { rand(1..7) }
  let(:workflow_my_group) { %w(enabled disabled).sample }
  let(:workflow_my_group_label) { I18n.t("ss.options.state.#{workflow_my_group}") }

  let(:workflow_route_approver_superior) { %w(show hide).sample }
  let(:workflow_route_approver_superior_label) { I18n.t("ss.options.state.#{workflow_route_approver_superior}") }
  let(:workflow_route_approver_title) { %w(show hide).sample }
  let(:workflow_route_approver_title_label) { I18n.t("ss.options.state.#{workflow_route_approver_title}") }
  let(:workflow_route_approver_occupation) { %w(show hide).sample }
  let(:workflow_route_approver_occupation_label) { I18n.t("ss.options.state.#{workflow_route_approver_occupation}") }

  let(:workflow_route_circulation_superior) { %w(show hide).sample }
  let(:workflow_route_circulation_superior_label) { I18n.t("ss.options.state.#{workflow_route_circulation_superior}") }
  let(:workflow_route_circulation_title) { %w(show hide).sample }
  let(:workflow_route_circulation_title_label) { I18n.t("ss.options.state.#{workflow_route_circulation_title}") }
  let(:workflow_route_circulation_occupation) { %w(show hide).sample }
  let(:workflow_route_circulation_occupation_label) { I18n.t("ss.options.state.#{workflow_route_circulation_occupation}") }

  context "basic crud" do
    before { login_gws_user }

    it do
      visit gws_site_path(site: site)
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        # open addon
        ensure_addon_opened("#addon-gws-agents-addons-workflow-group_setting")

        # fill form
        within "#addon-gws-agents-addons-workflow-group_setting" do
          fill_in "item[workflow_new_days]", with: workflow_new_days
          select workflow_my_group_label, from: "item[workflow_my_group]"

          select workflow_route_approver_superior_label, from: "item[workflow_route_approver_superior]"
          select workflow_route_approver_title_label, from: "item[workflow_route_approver_title]"
          select workflow_route_approver_occupation_label, from: "item[workflow_route_approver_occupation]"

          select workflow_route_circulation_superior_label, from: "item[workflow_route_circulation_superior]"
          select workflow_route_circulation_title_label, from: "item[workflow_route_circulation_title]"
          select workflow_route_circulation_occupation_label, from: "item[workflow_route_circulation_occupation]"
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      site.reload
      expect(site.workflow_new_days).to eq workflow_new_days
      expect(site.workflow_my_group).to eq workflow_my_group
      expect(site.workflow_route_approver_superior).to eq workflow_route_approver_superior
      expect(site.workflow_route_approver_title).to eq workflow_route_approver_title
      expect(site.workflow_route_approver_occupation).to eq workflow_route_approver_occupation
      expect(site.workflow_route_circulation_superior).to eq workflow_route_circulation_superior
      expect(site.workflow_route_circulation_title).to eq workflow_route_circulation_title
      expect(site.workflow_route_circulation_occupation).to eq workflow_route_circulation_occupation
    end
  end
end
