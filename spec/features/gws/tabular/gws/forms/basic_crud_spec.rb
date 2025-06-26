require 'spec_helper'

describe Gws::Tabular::Gws::FormsController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user) { create :gws_user, group_ids: [ group.id ], gws_role_ids: admin.gws_role_ids }
  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: user }

  context "basic crud" do
    let(:name_translations) { i18n_translations(prefix: "name") }
    let(:name_ja) { name_translations[:ja] }
    let(:name_en) { name_translations[:en] }
    let(:order) { rand(1..10) }
    let(:memo) { Array.new(2) { "memo-#{unique_id}" } }
    let(:workflow_state) { %w(enabled disabled).sample }
    let(:workflow_state_label) { I18n.t("ss.options.state.#{workflow_state}") }
    let(:approval_state) { %w(without_approval with_approval).sample }
    let(:approval_state_label) { I18n.t("gws/workflow2.options.approval_state.#{approval_state}") }
    let(:agent_state) { %w(enabled disabled).sample }
    let(:agent_state_label) { I18n.t("gws/workflow.options.agent_state.#{agent_state}") }

    let(:name2_translations) { i18n_translations(prefix: "name") }
    let(:name2_ja) { name2_translations[:ja] }
    let(:name2_en) { name2_translations[:en] }
    let(:order2) { rand(1..10) }
    let(:memo2) { Array.new(2) { "memo-#{unique_id}" } }
    let(:workflow_state2) { %w(enabled disabled).sample }
    let(:workflow_state2_label) { I18n.t("ss.options.state.#{workflow_state2}") }
    let(:approval_state2) { %w(without_approval with_approval).sample }
    let(:approval_state2_label) { I18n.t("gws/workflow2.options.approval_state.#{approval_state2}") }
    let(:agent_state2) { %w(enabled disabled).sample }
    let(:agent_state2_label) { I18n.t("gws/workflow.options.agent_state.#{agent_state2}") }

    it do
      #
      # New / Create
      #
      login_user user, to: gws_tabular_gws_spaces_path(site: site)
      click_on space.i18n_name
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/form")
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        # basic
        fill_in "item[i18n_name_translations][ja]", with: name_ja
        fill_in "item[i18n_name_translations][en]", with: name_en
        fill_in "item[order]", with: order
        fill_in "item[memo]", with: memo.join("\n")
        # workflow_setting
        select workflow_state_label, from: "item[workflow_state]"
        choose approval_state_label
        select agent_state_label, from: "item[agent_state]"
        within ".destination_group_ids" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.groups.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on group.trailing_name }
      end
      within "form#item-form" do
        within ".destination_group_ids" do
          expect(page).to have_css(".index [data-id='#{group.id}']", text: group.name)
        end

        within ".destination_user_ids" do
          wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
        end
      end
      within_cbox do
        wait_for_cbox_closed { click_on user.name }
      end
      within "form#item-form" do
        within ".destination_user_ids" do
          expect(page).to have_css(".index [data-id='#{user.id}']", text: user.name)
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Tabular::Form.all.count).to eq 1
      Gws::Tabular::Form.all.first.tap do |form|
        expect(form.i18n_name_translations[:ja]).to eq name_ja
        expect(form.i18n_name_translations[:en]).to eq name_en
        expect(form.state).to eq "closed"
        expect(form.order).to eq order
        expect(form.memo).to eq memo.join("\r\n")
        expect(form.revision).to be_blank
        # Gws::Addon::Tabular::WorkflowSetting
        expect(form.workflow_state).to eq workflow_state
        expect(form.approval_state).to eq approval_state
        expect(form.default_route_id).to eq "my_group"
        expect(form.agent_state).to eq agent_state
        expect(form.destination_group_ids).to eq [ group.id ]
        expect(form.destination_user_ids).to eq [ user.id ]
        # Gws::Addon::ReadableSetting
        expect(form.readable_setting_range).to eq "select"
        expect(form.readable_member_ids).to be_blank
        expect(form.readable_group_ids).to eq [ group.id ]
        expect(form.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(form.user_ids).to eq [ user.id ]
        expect(form.group_ids).to eq [ group.id ]
        expect(form.custom_group_ids).to be_blank
        #
        expect(form.site_id).to eq site.id
        expect(form.space_id).to eq space.id
        expect(form.deleted).to be_blank
      end

      #
      # Edit / Update
      #
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/form")
      end
      expect(page).to have_css(".list-item[data-id]", text: name_translations[I18n.locale])
      click_on name_translations[I18n.locale]
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        # basic
        fill_in "item[i18n_name_translations][ja]", with: name2_ja
        fill_in "item[i18n_name_translations][en]", with: name2_en
        fill_in "item[order]", with: order2
        fill_in "item[memo]", with: memo2.join("\n")
        # workflow_setting
        select workflow_state2_label, from: "item[workflow_state]"
        choose approval_state2_label
        select agent_state2_label, from: "item[agent_state]"

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Tabular::Form.all.count).to eq 1
      Gws::Tabular::Form.all.first.tap do |form|
        expect(form.i18n_name_translations[:ja]).to eq name2_ja
        expect(form.i18n_name_translations[:en]).to eq name2_en
        expect(form.state).to eq "closed"
        expect(form.order).to eq order2
        expect(form.memo).to eq memo2.join("\r\n")
        expect(form.revision).to be_blank
        # Gws::Addon::Tabular::WorkflowSetting
        expect(form.workflow_state).to eq workflow_state2
        expect(form.approval_state).to eq approval_state2
        expect(form.default_route_id).to eq "my_group"
        expect(form.agent_state).to eq agent_state2
        expect(form.destination_group_ids).to eq [ group.id ]
        expect(form.destination_user_ids).to eq [ user.id ]
        # Gws::Addon::ReadableSetting
        expect(form.readable_setting_range).to eq "select"
        expect(form.readable_member_ids).to be_blank
        expect(form.readable_group_ids).to eq [ group.id ]
        expect(form.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(form.user_ids).to eq [ user.id ]
        expect(form.group_ids).to eq [ group.id ]
        expect(form.custom_group_ids).to be_blank
        #
        expect(form.site_id).to eq site.id
        expect(form.space_id).to eq space.id
        expect(form.deleted).to be_blank
      end

      #
      # Soft Delete
      #
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/form")
      end
      expect(page).to have_css(".list-item[data-id]", text: name2_translations[I18n.locale])
      click_on name2_translations[I18n.locale]
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Tabular::Form.all.count).to eq 1
      Gws::Tabular::Form.all.first.tap do |form|
        expect(form.i18n_name_translations[:ja]).to eq name2_ja
        expect(form.i18n_name_translations[:en]).to eq name2_en
        expect(form.state).to eq "closed"
        expect(form.order).to eq order2
        expect(form.memo).to eq memo2.join("\r\n")
        expect(form.revision).to be_blank
        # Gws::Addon::Tabular::WorkflowSetting
        expect(form.workflow_state).to eq workflow_state2
        expect(form.approval_state).to eq approval_state2
        expect(form.default_route_id).to eq "my_group"
        expect(form.agent_state).to eq agent_state2
        expect(form.destination_group_ids).to eq [ group.id ]
        expect(form.destination_user_ids).to eq [ user.id ]
        # Gws::Addon::ReadableSetting
        expect(form.readable_setting_range).to eq "select"
        expect(form.readable_member_ids).to be_blank
        expect(form.readable_group_ids).to eq [ group.id ]
        expect(form.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(form.user_ids).to eq [ user.id ]
        expect(form.group_ids).to eq [ group.id ]
        expect(form.custom_group_ids).to be_blank
        #
        expect(form.site_id).to eq site.id
        expect(form.space_id).to eq space.id
        expect(form.deleted.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
      end

      #
      # Undo Delete
      #
      within first(".mod-navi") do
        click_on I18n.t("mongoid.models.gws/tabular/form")
      end
      expect(page).to have_css(".list-item[data-id]", count: 0)
      within first(".mod-navi") do
        click_on "delete"
      end
      expect(page).to have_css(".list-item[data-id]", count: 1)
      click_on name2_translations[I18n.locale]
      within ".nav-menu" do
        click_on I18n.t("ss.links.restore")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.restore")
      end
      wait_for_notice I18n.t("ss.notice.restored")

      expect(Gws::Tabular::Form.all.count).to eq 1
      Gws::Tabular::Form.all.first.tap do |form|
        expect(form.i18n_name_translations[:ja]).to eq name2_ja
        expect(form.i18n_name_translations[:en]).to eq name2_en
        expect(form.state).to eq "closed"
        expect(form.order).to eq order2
        expect(form.memo).to eq memo2.join("\r\n")
        expect(form.revision).to be_blank
        # Gws::Addon::Tabular::WorkflowSetting
        expect(form.workflow_state).to eq workflow_state2
        expect(form.approval_state).to eq approval_state2
        expect(form.default_route_id).to eq "my_group"
        expect(form.agent_state).to eq agent_state2
        expect(form.destination_group_ids).to eq [ group.id ]
        expect(form.destination_user_ids).to eq [ user.id ]
        # Gws::Addon::ReadableSetting
        expect(form.readable_setting_range).to eq "select"
        expect(form.readable_member_ids).to be_blank
        expect(form.readable_group_ids).to eq [ group.id ]
        expect(form.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(form.user_ids).to eq [ user.id ]
        expect(form.group_ids).to eq [ group.id ]
        expect(form.custom_group_ids).to be_blank
        #
        expect(form.site_id).to eq site.id
        expect(form.space_id).to eq space.id
        expect(form.deleted).to be_blank
      end
    end
  end
end
