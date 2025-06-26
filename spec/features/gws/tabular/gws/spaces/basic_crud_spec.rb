require 'spec_helper'

describe Gws::Tabular::Gws::SpacesController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let(:group) { gws_user.groups.first }

  context "basic crud" do
    let(:name_translations) { i18n_translations(prefix: "name") }
    let(:name_ja) { name_translations[:ja] }
    let(:name_en) { name_translations[:en] }
    let(:state) { %w(public closed).sample }
    let(:state_label) { I18n.t("ss.options.state.#{state}") }
    let(:order) { rand(1..10) }
    let(:memo) { Array.new(2) { "memo-#{unique_id}" } }

    let(:name2_translations) { i18n_translations(prefix: "name") }
    let(:name2_ja) { name2_translations[:ja] }
    let(:name2_en) { name2_translations[:en] }
    let(:state2) { %w(public closed).sample }
    let(:state2_label) { I18n.t("ss.options.state.#{state2}") }
    let(:order2) { rand(11..20) }
    let(:memo2) { Array.new(2) { "memo-#{unique_id}" } }

    it do
      #
      # New / Create
      #
      login_user admin, to: gws_tabular_gws_spaces_path(site: site)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[i18n_name_translations][ja]", with: name_ja
        fill_in "item[i18n_name_translations][en]", with: name_en
        select state_label, from: "item[state]"
        fill_in "item[order]", with: order
        fill_in "item[memo]", with: memo.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Tabular::Space.all.count).to eq 1
      Gws::Tabular::Space.all.first.tap do |space|
        expect(space.i18n_name_translations[:ja]).to eq name_ja
        expect(space.i18n_name_translations[:en]).to eq name_en
        expect(space.state).to eq state
        expect(space.order).to eq order
        expect(space.memo).to eq memo.join("\r\n")
        # Gws::Addon::ReadableSetting
        expect(space.readable_setting_range).to eq "select"
        expect(space.readable_member_ids).to be_blank
        expect(space.readable_group_ids).to eq [ group.id ]
        expect(space.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(space.user_ids).to eq [ admin.id ]
        expect(space.group_ids).to eq [ group.id ]
        expect(space.custom_group_ids).to be_blank
        #
        expect(space.site_id).to eq site.id
        expect(space.deleted).to be_blank
      end

      #
      # Edit / Update
      #
      visit gws_tabular_gws_spaces_path(site: site)
      expect(page).to have_css(".list-item[data-id]", text: name_translations[I18n.locale])
      within ".list-item[data-id]" do
        click_on "tune"
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[i18n_name_translations][ja]", with: name2_ja
        fill_in "item[i18n_name_translations][en]", with: name2_en
        select state2_label, from: "item[state]"
        fill_in "item[order]", with: order2
        fill_in "item[memo]", with: memo2.join("\n")

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Tabular::Space.all.count).to eq 1
      Gws::Tabular::Space.all.first.tap do |space|
        expect(space.i18n_name_translations[:ja]).to eq name2_ja
        expect(space.i18n_name_translations[:en]).to eq name2_en
        expect(space.state).to eq state2
        expect(space.order).to eq order2
        expect(space.memo).to eq memo2.join("\r\n")
        # Gws::Addon::ReadableSetting
        expect(space.readable_setting_range).to eq "select"
        expect(space.readable_member_ids).to be_blank
        expect(space.readable_group_ids).to eq [ group.id ]
        expect(space.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(space.user_ids).to eq [ admin.id ]
        expect(space.group_ids).to eq [ group.id ]
        expect(space.custom_group_ids).to be_blank
        #
        expect(space.site_id).to eq site.id
        expect(space.deleted).to be_blank
      end

      #
      # Soft Delete
      #
      visit gws_tabular_gws_spaces_path(site: site)
      expect(page).to have_css(".list-item[data-id]", text: name2_translations[I18n.locale])
      within ".list-item[data-id]" do
        click_on "tune"
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Tabular::Space.all.count).to eq 1
      Gws::Tabular::Space.all.first.tap do |space|
        expect(space.i18n_name_translations[:ja]).to eq name2_ja
        expect(space.i18n_name_translations[:en]).to eq name2_en
        expect(space.state).to eq state2
        expect(space.order).to eq order2
        expect(space.memo).to eq memo2.join("\r\n")
        # Gws::Addon::ReadableSetting
        expect(space.readable_setting_range).to eq "select"
        expect(space.readable_member_ids).to be_blank
        expect(space.readable_group_ids).to eq [ group.id ]
        expect(space.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(space.user_ids).to eq [ admin.id ]
        expect(space.group_ids).to eq [ group.id ]
        expect(space.custom_group_ids).to be_blank
        #
        expect(space.site_id).to eq site.id
        expect(space.deleted.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
      end

      #
      # Undo Delete
      #
      visit gws_tabular_gws_spaces_path(site: site)
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

      expect(Gws::Tabular::Space.all.count).to eq 1
      Gws::Tabular::Space.all.first.tap do |space|
        expect(space.i18n_name_translations[:ja]).to eq name2_ja
        expect(space.i18n_name_translations[:en]).to eq name2_en
        expect(space.state).to eq state2
        expect(space.order).to eq order2
        expect(space.memo).to eq memo2.join("\r\n")
        # Gws::Addon::ReadableSetting
        expect(space.readable_setting_range).to eq "select"
        expect(space.readable_member_ids).to be_blank
        expect(space.readable_group_ids).to eq [ group.id ]
        expect(space.readable_custom_group_ids).to be_blank
        # Gws::Addon::GroupPermission
        expect(space.user_ids).to eq [ admin.id ]
        expect(space.group_ids).to eq [ group.id ]
        expect(space.custom_group_ids).to be_blank
        #
        expect(space.site_id).to eq site.id
        expect(space.deleted).to be_blank
      end
    end
  end
end
