require 'spec_helper'

describe Cms::Line::ApplyRichmenuJob, dbscope: :example do
  let!(:site) { cms_site }

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  def registrations
    Cms::Line::Richmenu::Registration.site(site).all
  end

  context "no menu" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!
    end

    it do
      capture_line_bot_client do |capture|
        described_class.bind(site_id: site).perform_now
        expect(Job::Log.count).to eq 1
        expect(capture.create_rich_menu.count).to eq 0
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 0
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 0
        expect(registrations.size).to eq 0
      end
    end
  end

  context "default menu" do
    let!(:menu1_image) do
      Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/cms/line/richmenu_small1.png")
    end
    let(:menu1_in_areas1) do
      [ { x: 0, y: 0, width: 800, height: 270, type: "message", text: unique_id } ]
    end
    let(:menu1_in_area2) do
      [ { x: 0, y: 0, width: 800, height: 270, type: "uri", uri: site.full_url } ]
    end
    let!(:richmenu_menu) do
      create(:cms_line_richmenu_menu,
        group: richmenu_group,
        in_image: menu1_image,
        target: "default",
        area_size: 1,
        width: 800,
        height: 270,
        in_areas: menu1_in_areas1
      )
    end
    let!(:richmenu_group) { create :cms_line_richmenu_group }

    it do
      capture_line_bot_client do |capture|
        # create
        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 1
        expect(capture.create_rich_menu.rich_menu).to eq richmenu_menu.richmenu_object
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 1
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 0
        expect(registrations.size).to eq 1
        registration = registrations.where(menu_id: richmenu_menu.id).first
        expect(registration.line_richmenu_id).to eq "richMenuId-1"

        # update (not changed)
        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 1
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 2
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 0
        expect(registrations.size).to eq 1
        registration = registrations.where(menu_id: richmenu_menu.id).first
        expect(registration.line_richmenu_id).to eq "richMenuId-1"

        # update (changed)
        richmenu_menu.in_areas = menu1_in_area2
        richmenu_menu.save!
        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 3
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-2"
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 1
        expect(capture.delete_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(registrations.size).to eq 1
        registration = registrations.where(menu_id: richmenu_menu.id).first
        expect(registration.line_richmenu_id).to eq "richMenuId-2"

        # destroy
        richmenu_group.destroy
        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 3
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 2
        expect(capture.delete_rich_menu.rich_menu_id).to eq "richMenuId-2"
        expect(registrations.size).to eq 0
      end
    end
  end

  context "tab menu" do
    let!(:menu1_image) do
      Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/cms/line/richmenu_small1.png")
    end
    let!(:menu2_image) do
      Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/cms/line/richmenu_small2.png")
    end
    let(:menu1_in_areas1) do
      [ { x: 0, y: 0, width: 800, height: 270, type: "message", text: unique_id } ]
    end
    let(:menu1_in_areas2) do
      [ { x: 0, y: 0, width: 800, height: 270, type: "richmenuswitch", menu_id: tab_menu.id } ]
    end
    let(:menu2_in_areas1) do
      [
        { x: 0, y: 0, width: 400, height: 270, type: "message", text: unique_id },
        { x: 400, y: 0, width: 400, height: 270, type: "message", text: unique_id },
      ]
    end
    let(:menu2_in_areas2) do
      [
        { x: 0, y: 0, width: 400, height: 270, type: "message", text: unique_id },
        { x: 400, y: 0, width: 400, height: 270, type: "richmenuswitch", menu_id: default_menu.id },
      ]
    end
    let!(:default_menu) do
      create(:cms_line_richmenu_menu,
        group: richmenu_group,
        in_image: menu1_image,
        target: "default",
        area_size: 1,
        width: 800,
        height: 270,
        in_areas: menu1_in_areas1,
        order: 10
      )
    end
    let!(:tab_menu) do
      create(:cms_line_richmenu_menu,
        group: richmenu_group,
        in_image: menu2_image,
        target: "switch",
        area_size: 2,
        width: 800,
        height: 270,
        in_areas: menu2_in_areas1,
        order: 20
      )
    end
    let!(:richmenu_group) { create :cms_line_richmenu_group }

    it do
      capture_line_bot_client do |capture|
        # create
        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.create_rich_menu.rich_menu).to eq tab_menu.richmenu_object
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 1
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 0
        expect(registrations.size).to eq 2
        expect(registrations.pluck(:menu_id, :line_richmenu_id)).to match_array(
          [[default_menu.id, "richMenuId-1"], [tab_menu.id, "richMenuId-2"]])

        # update (changed)
        default_menu.in_areas = menu1_in_areas2
        default_menu.save!
        default_menu.reload
        tab_menu.in_areas = menu2_in_areas2
        tab_menu.save!
        tab_menu.reload

        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 4
        expect(capture.create_rich_menu.rich_menu).to eq tab_menu.richmenu_object
        expect(capture.get_rich_menus_alias_list.count).to eq 1
        expect(capture.set_rich_menus_alias.count).to eq 2
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 2
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-3"
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 2
        expect(registrations.size).to eq 2
        expect(registrations.pluck(:menu_id, :line_richmenu_id)).to match_array(
          [[default_menu.id, "richMenuId-3"], [tab_menu.id, "richMenuId-4"]])

        # update (changed)
        tab_menu.name = "modified"
        tab_menu.save!
        tab_menu.reload

        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 5
        expect(capture.create_rich_menu.rich_menu).to eq tab_menu.richmenu_object
        expect(capture.get_rich_menus_alias_list.count).to eq 2
        expect(capture.set_rich_menus_alias.count).to eq 2
        expect(capture.update_rich_menus_alias.count).to eq 2
        expect(capture.set_default_rich_menu.count).to eq 3
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-3"
        expect(capture.bulk_link_rich_menus.count).to eq 0
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 3
        expect(registrations.size).to eq 2
        expect(registrations.pluck(:menu_id, :line_richmenu_id)).to match_array(
          [[default_menu.id, "richMenuId-3"], [tab_menu.id, "richMenuId-5"]])
      end
    end
  end

  context "member menu" do
    let!(:menu1_image) do
      Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/cms/line/richmenu_small1.png")
    end
    let!(:menu2_image) do
      Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/cms/line/richmenu_small2.png")
    end
    let(:menu1_in_areas1) do
      [ { x: 0, y: 0, width: 800, height: 270, type: "message", text: unique_id } ]
    end
    let(:menu2_in_areas1) do
      [ { x: 0, y: 0, width: 800, height: 270, type: "uri", uri: site.full_url } ]
    end
    let!(:default_menu) do
      create(:cms_line_richmenu_menu,
        group: richmenu_group,
        in_image: menu1_image,
        target: "default",
        area_size: 1,
        width: 800,
        height: 270,
        in_areas: menu1_in_areas1,
        order: 10
      )
    end
    let!(:member_menu) do
      create(:cms_line_richmenu_menu,
        group: richmenu_group,
        in_image: menu2_image,
        target: "member",
        area_size: 2,
        width: 800,
        height: 270,
        in_areas: menu2_in_areas1,
        order: 20
      )
    end
    let!(:richmenu_group) { create :cms_line_richmenu_group }
    let(:member1) { create :cms_member }
    let(:member2) { create :cms_member, oauth_type: "line", oauth_id: unique_id }
    let(:member3) { create :cms_member, oauth_type: "line", oauth_id: unique_id }
    let(:member4) { create :cms_member, oauth_type: "line", oauth_id: unique_id }

    it do
      capture_line_bot_client do |capture|
        member1
        member2

        # create
        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 1
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(capture.bulk_link_rich_menus.count).to eq 1
        expect(capture.bulk_link_rich_menus.user_ids).to match_array([member2.oauth_id])
        expect(capture.bulk_link_rich_menus.line_richmenu_id).to eq "richMenuId-2"
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 0

        expect(registrations.size).to eq 2
        registration1 = registrations.find_by(menu_id: default_menu.id)
        expect(registration1.line_richmenu_id).to eq "richMenuId-1"
        expect(registration1.linked_user_ids).to match_array([])
        registration2 = registrations.find_by(menu_id: member_menu.id)
        expect(registration2.line_richmenu_id).to eq "richMenuId-2"
        expect(registration2.linked_user_ids).to match_array([member2.oauth_id])

        member1.reload
        member2.reload
        expect(member1.subscribe_richmenu_id).to eq nil
        expect(member2.subscribe_richmenu_id).to eq "richMenuId-2"

        # update (not changed)
        member3
        member4

        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 2
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(capture.bulk_link_rich_menus.count).to eq 2
        expect(capture.bulk_link_rich_menus.user_ids).to match_array([member3.oauth_id, member4.oauth_id])
        expect(capture.bulk_link_rich_menus.line_richmenu_id).to eq "richMenuId-2"
        expect(capture.bulk_unlink_rich_menus.count).to eq 0
        expect(capture.delete_rich_menu.count).to eq 0

        expect(registrations.size).to eq 2
        registration1 = registrations.find_by(menu_id: default_menu.id)
        expect(registration1.line_richmenu_id).to eq "richMenuId-1"
        expect(registration1.linked_user_ids).to match_array([])
        registration2 = registrations.find_by(menu_id: member_menu.id)
        expect(registration2.line_richmenu_id).to eq "richMenuId-2"
        expect(registration2.linked_user_ids).to match_array(
          [member2.oauth_id, member3.oauth_id, member4.oauth_id])

        member1.reload
        member2.reload
        member3.reload
        member4.reload

        expect(member1.subscribe_richmenu_id).to eq nil
        expect(member2.subscribe_richmenu_id).to eq "richMenuId-2"
        expect(member3.subscribe_richmenu_id).to eq "richMenuId-2"
        expect(member4.subscribe_richmenu_id).to eq "richMenuId-2"

        # destroy member4
        member4_user_id = member4.oauth_id
        member4.destroy

        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 3
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(capture.bulk_link_rich_menus.count).to eq 2
        expect(capture.bulk_unlink_rich_menus.count).to eq 1
        expect(capture.bulk_unlink_rich_menus.user_ids).to match_array([member4_user_id])
        expect(capture.delete_rich_menu.count).to eq 0

        expect(registrations.size).to eq 2
        registration1 = registrations.find_by(menu_id: default_menu.id)
        expect(registration1.line_richmenu_id).to eq "richMenuId-1"
        expect(registration1.linked_user_ids).to match_array([])
        registration2 = registrations.find_by(menu_id: member_menu.id)
        expect(registration2.line_richmenu_id).to eq "richMenuId-2"
        expect(registration2.linked_user_ids).to match_array(
          [member2.oauth_id, member3.oauth_id])

        member1.reload
        member2.reload
        member3.reload

        expect(member1.subscribe_richmenu_id).to eq nil
        expect(member2.subscribe_richmenu_id).to eq "richMenuId-2"
        expect(member3.subscribe_richmenu_id).to eq "richMenuId-2"

        # disable member3
        member3.state = "disabled"
        member3.save

        described_class.bind(site_id: site).perform_now

        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 4
        expect(capture.set_default_rich_menu.rich_menu_id).to eq "richMenuId-1"
        expect(capture.bulk_link_rich_menus.count).to eq 2
        expect(capture.bulk_unlink_rich_menus.count).to eq 2
        expect(capture.bulk_unlink_rich_menus.user_ids).to match_array([member3.oauth_id])
        expect(capture.delete_rich_menu.count).to eq 0

        expect(registrations.size).to eq 2
        registration1 = registrations.find_by(menu_id: default_menu.id)
        expect(registration1.line_richmenu_id).to eq "richMenuId-1"
        expect(registration1.linked_user_ids).to match_array([])
        registration2 = registrations.find_by(menu_id: member_menu.id)
        expect(registration2.line_richmenu_id).to eq "richMenuId-2"
        expect(registration2.linked_user_ids).to match_array(
          [member2.oauth_id])

        member1.reload
        member2.reload
        member3.reload

        expect(member1.subscribe_richmenu_id).to eq nil
        expect(member2.subscribe_richmenu_id).to eq "richMenuId-2"
        expect(member3.subscribe_richmenu_id).to eq nil

        # destroy
        richmenu_group.destroy
        described_class.bind(site_id: site).perform_now
        expect(capture.create_rich_menu.count).to eq 2
        expect(capture.get_rich_menus_alias_list.count).to eq 0
        expect(capture.set_rich_menus_alias.count).to eq 0
        expect(capture.update_rich_menus_alias.count).to eq 0
        expect(capture.set_default_rich_menu.count).to eq 4
        expect(capture.bulk_link_rich_menus.count).to eq 2
        expect(capture.bulk_unlink_rich_menus.count).to eq 2
        expect(capture.delete_rich_menu.count).to eq 2
        expect(capture.delete_rich_menu.rich_menu_id).to eq "richMenuId-2"
        expect(registrations.size).to eq 0

        member1.reload
        member2.reload
        member3.reload

        expect(member1.subscribe_richmenu_id).to eq nil
        expect(member2.subscribe_richmenu_id).to eq nil
        expect(member3.subscribe_richmenu_id).to eq nil
      end
    end
  end
end
