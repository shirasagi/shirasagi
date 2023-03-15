require 'spec_helper'

describe "member_groups", type: :feature, js: true do
  let(:site) { cms_site }

  let(:member1) { create :cms_member }
  let(:member2) { create :cms_member }
  let(:member3) { create :cms_member }
  let!(:item) { create :member_group, in_admin_member_ids: [member1.id, member2.id, member3.id] }

  let(:index_path) { member_groups_path site.id }
  let(:new_path) { new_member_group_path site.id }
  let(:show_path) { member_group_path site.id, item }
  let(:edit_path) { edit_member_group_path site.id, item }
  let(:delete_path) { delete_member_group_path site.id, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css('a.title', text: item.name)
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[invitation_message]", with: "invitation"
        wait_cbox_open { click_on I18n.t("cms.apis.members.index") }
      end

      wait_for_cbox do
        first('#ajax-box th [type="checkbox"]').set(true)
        click_on I18n.t("cms.apis.members.select")
        wait_for_ajax
      end

      within "form#item-form" do
        click_button I18n.t("ss.buttons.save")
      end

      within "#addon-basic" do
        expect(page).to have_css('dd', text: "sample")
        expect(page).to have_css('dd', text: "invitation")
      end

      within "#navi" do
        click_on I18n.t("member.group_member")
      end

      expect(page).to have_css('a.title', text: member1.name)
      expect(page).to have_css('a.title', text: member2.name)
      expect(page).to have_css('a.title', text: member3.name)
    end

    it "#show" do
      visit show_path

      within "#addon-basic" do
        expect(page).to have_css('dd', text: item.name)
        expect(page).to have_css('dd', text: item.invitation_message)
      end

      within "#navi" do
        click_on I18n.t("member.group_member")
      end

      expect(page).to have_css('a.title', text: member1.name)
      expect(page).to have_css('a.title', text: member2.name)
      expect(page).to have_css('a.title', text: member3.name)
    end

    it "#edit" do
      visit edit_path

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[invitation_message]", with: "invitation"
        click_button I18n.t("ss.buttons.save")
      end

      within "#addon-basic" do
        expect(page).to have_css('dd', text: "sample")
        expect(page).to have_css('dd', text: "invitation")
      end

      within "#navi" do
        click_on I18n.t("member.group_member")
      end

      expect(page).to have_css('a.title', text: member1.name)
      expect(page).to have_css('a.title', text: member2.name)
      expect(page).to have_css('a.title', text: member3.name)
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end
  end
end
