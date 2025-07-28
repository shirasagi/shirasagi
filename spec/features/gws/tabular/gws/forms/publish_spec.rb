require 'spec_helper'

describe Gws::Tabular::Gws::FormsController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user) { create :gws_user, group_ids: [ group.id ], gws_role_ids: admin.gws_role_ids }
  let!(:space) { create :gws_tabular_space, cur_site: site, cur_user: user }

  context "create and publish" do
    let(:name_translations) { i18n_translations(prefix: "name") }
    let(:name_ja) { name_translations[:ja] }
    let(:name_en) { name_translations[:en] }
    let(:order) { rand(1..10) }
    let(:memo) { Array.new(2) { "memo-#{unique_id}" } }

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
        expect(form.workflow_state).to eq "disabled"
        expect(form.approval_state).to eq "with_approval"
        expect(form.default_route_id).to eq "my_group"
        expect(form.agent_state).to eq "disabled"
        expect(form.destination_group_ids).to be_blank
        expect(form.destination_user_ids).to be_blank
        # Gws::Addon::ReadableSetting
        expect(form.readable_setting_range).to eq "select"
        expect(form.readable_member_ids).to be_blank
        expect(form.readable_group_ids).to eq [ group.id ]
        expect(form.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(form.user_ids).to eq [ user.id ]
        expect(form.group_ids).to eq [ group.id ]
        expect(form.custom_group_ids).to be_blank
        # Common
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
        click_on I18n.t("gws/workflow.links.publish")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.publish")
      end
      wait_for_notice I18n.t("ss.notice.published")

      expect(Gws::Tabular::Form.all.count).to eq 1
      Gws::Tabular::Form.all.first.tap do |form|
        expect(form.i18n_name_translations[:ja]).to eq name_ja
        expect(form.i18n_name_translations[:en]).to eq name_en
        expect(form.state).to eq "public"
        expect(form.order).to eq order
        expect(form.memo).to eq memo.join("\r\n")
        expect(form.revision).to eq 1
        # Gws::Addon::Tabular::WorkflowSetting
        expect(form.workflow_state).to eq "disabled"
        expect(form.approval_state).to eq "with_approval"
        expect(form.default_route_id).to eq "my_group"
        expect(form.agent_state).to eq "disabled"
        expect(form.destination_group_ids).to be_blank
        expect(form.destination_user_ids).to be_blank
        # Gws::Addon::ReadableSetting
        expect(form.readable_setting_range).to eq "select"
        expect(form.readable_member_ids).to be_blank
        expect(form.readable_group_ids).to eq [ group.id ]
        expect(form.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(form.user_ids).to eq [ user.id ]
        expect(form.group_ids).to eq [ group.id ]
        expect(form.custom_group_ids).to be_blank
        # Common
        expect(form.site_id).to eq site.id
        expect(form.space_id).to eq space.id
        expect(form.deleted).to be_blank
      end

      # Gws::Tabular::FormPublishJob が perform_now で即時実行されるのでジョブログが作成されている
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.all.each do |log|
        expect(log.class_name).to eq "Gws::Tabular::FormPublishJob"
        expect(log.args).to have(1).items
        expect(log.args[0]).to eq Gws::Tabular::Form.all.only(:id).first.id.to_s
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end
end
