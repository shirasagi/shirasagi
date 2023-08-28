require 'spec_helper'

describe "chorg_changesets", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:revision) { create(:revision, cur_site: site) }
  let!(:group) do
    create(
      :cms_group, name: "#{cms_group.name}/#{unique_id}",
      contact_groups: [
        {
          main_state: "main", name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        },
        {
          main_state: nil, name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
          contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
          contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        }
      ]
    )
  end

  before do
    login_cms_user
  end

  context "basic crud: division" do
    let(:new_name1) { "name-#{unique_id}" }
    let(:new_name11) { "name-#{unique_id}" }
    let(:new_order1) { rand(1..10) }
    let(:new_ldap_dn1) { "dc=#{new_name1},dc=city,dc=example,dc=jp" }
    let(:new_name2) { "name-#{unique_id}" }
    let(:new_order2) { rand(1..10) }
    let(:new_ldap_dn2) { "dc=#{new_name2},dc=city,dc=example,dc=jp" }
    let(:new_name3) { "name-#{unique_id}" }
    let(:new_order3) { rand(1..10) }
    let(:new_ldap_dn3) { "dc=#{new_name3},dc=city,dc=example,dc=jp" }

    it do
      #
      # Create
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-division" do
        click_on I18n.t("chorg.menus.revisions.division")
      end
      within "form#item-form" do
        within "#chorg-before-basic" do
          wait_cbox_open { click_on I18n.t("chorg.views.division_changesets.select_group") }
        end
      end
      wait_event_to_fire "turbo:frame-load" do
        page.accept_confirm I18n.t("chorg.confirm.reset_after_division") do
          wait_for_cbox do
            click_on group.trailing_name
          end
        end
      end
      within "form#item-form" do
        # 1 番目の分割先
        within "#chorg-after-basic1" do
          fill_in "item[destinations][][name]", with: new_name1
          fill_in "item[destinations][][order]", with: new_order1
        end
        within "#chorg-after-ldap1" do
          fill_in "item[destinations][][ldap_dn]", with: new_ldap_dn1
        end
        within "#chorg-after-contact1" do
          within first("tr[data-id='#{group.contact_groups[1].id}']") do
            click_on I18n.t("ss.buttons.delete")
          end
        end

        # 2 番目の分割先
        within "#chorg-after-basic2" do
          fill_in "item[destinations][][name]", with: new_name2
          fill_in "item[destinations][][order]", with: new_order2
        end
        within "#chorg-after-ldap2" do
          fill_in "item[destinations][][ldap_dn]", with: new_ldap_dn2
        end
        within "#chorg-after-contact2" do
          within first("tr[data-id='#{group.contact_groups[0].id}']") do
            click_on I18n.t("ss.buttons.delete")
          end
          within first("tr[data-id='#{group.contact_groups[1].id}']") do
            # click_on I18n.t("contact.options.main_state.main")
            first('[name="dummy[chorg-after-contact2][][main_state]"]').click
          end
        end

        # 3 番目の分割先
        within "[data-sequence='3']" do
          click_on I18n.t("ss.buttons.clear")
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      revision.reload
      expect(revision.changesets).to have(1).items
      revision.changesets.first.tap do |changeset|
        expect(changeset.revision_id).to eq revision.id
        expect(changeset.type).to eq "division"
        expect(changeset.sources).to have(1).items
        changeset.sources.first.tap do |source|
          expect(source["id"]).to eq group.id.to_s
          expect(source["name"]).to eq group.name
        end
        changeset.destinations[0].tap do |destination|
          expect(destination[:name]).to eq new_name1
          expect(destination[:order]).to eq new_order1.to_s
          expect(destination[:ldap_dn]).to eq new_ldap_dn1
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups][0].tap do |contact_group|
            group.contact_groups[0].tap do |source_contact_group|
              expect(contact_group[:_id]).to eq source_contact_group.id.to_s
              expect(contact_group[:main_state]).to eq "main"
              expect(contact_group[:name]).to eq source_contact_group.name
              expect(contact_group[:contact_group_name]).to eq source_contact_group.contact_group_name
              expect(contact_group[:contact_tel]).to eq source_contact_group.contact_tel
              expect(contact_group[:contact_fax]).to eq source_contact_group.contact_fax
              expect(contact_group[:contact_email]).to eq source_contact_group.contact_email
              expect(contact_group[:contact_link_url]).to eq source_contact_group.contact_link_url
              expect(contact_group[:contact_link_name]).to eq source_contact_group.contact_link_name
            end
          end
        end
        changeset.destinations[1].tap do |destination|
          expect(destination[:name]).to eq new_name2
          expect(destination[:order]).to eq new_order2.to_s
          expect(destination[:ldap_dn]).to eq new_ldap_dn2
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups][0].tap do |contact_group|
            group.contact_groups[1].tap do |source_contact_group|
              expect(contact_group[:_id]).to eq source_contact_group.id.to_s
              expect(contact_group[:main_state]).to eq "main"
              expect(contact_group[:name]).to eq source_contact_group.name
              expect(contact_group[:contact_group_name]).to eq source_contact_group.contact_group_name
              expect(contact_group[:contact_tel]).to eq source_contact_group.contact_tel
              expect(contact_group[:contact_fax]).to eq source_contact_group.contact_fax
              expect(contact_group[:contact_email]).to eq source_contact_group.contact_email
              expect(contact_group[:contact_link_url]).to eq source_contact_group.contact_link_url
              expect(contact_group[:contact_link_name]).to eq source_contact_group.contact_link_name
            end
          end
        end
      end

      #
      # Update
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-division" do
        click_on [ new_name1, new_name2 ].join(",")
      end
      expect(page).to have_css("#chorg-after-basic1", text: new_name1)
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        within "#chorg-after-basic1" do
          fill_in "item[destinations][][name]", with: new_name11
        end
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      revision.reload
      expect(revision.changesets).to have(1).items
      revision.changesets.first.tap do |changeset|
        expect(changeset.revision_id).to eq revision.id
        expect(changeset.type).to eq "division"
        expect(changeset.sources).to have(1).items
        changeset.sources.first.tap do |source|
          expect(source["id"]).to eq group.id.to_s
          expect(source["name"]).to eq group.name
        end
        changeset.destinations[0].tap do |destination|
          expect(destination[:name]).to eq new_name11
          expect(destination[:order]).to eq new_order1.to_s
          expect(destination[:ldap_dn]).to eq new_ldap_dn1
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups][0].tap do |contact_group|
            group.contact_groups[0].tap do |source_contact_group|
              expect(contact_group[:_id]).to eq source_contact_group.id.to_s
              expect(contact_group[:main_state]).to eq "main"
              expect(contact_group[:name]).to eq source_contact_group.name
              expect(contact_group[:contact_group_name]).to eq source_contact_group.contact_group_name
              expect(contact_group[:contact_tel]).to eq source_contact_group.contact_tel
              expect(contact_group[:contact_fax]).to eq source_contact_group.contact_fax
              expect(contact_group[:contact_email]).to eq source_contact_group.contact_email
              expect(contact_group[:contact_link_url]).to eq source_contact_group.contact_link_url
              expect(contact_group[:contact_link_name]).to eq source_contact_group.contact_link_name
            end
          end
        end
        changeset.destinations[1].tap do |destination|
          expect(destination[:name]).to eq new_name2
          expect(destination[:order]).to eq new_order2.to_s
          expect(destination[:ldap_dn]).to eq new_ldap_dn2
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups][0].tap do |contact_group|
            group.contact_groups[1].tap do |source_contact_group|
              expect(contact_group[:_id]).to eq source_contact_group.id.to_s
              expect(contact_group[:main_state]).to eq "main"
              expect(contact_group[:name]).to eq source_contact_group.name
              expect(contact_group[:contact_group_name]).to eq source_contact_group.contact_group_name
              expect(contact_group[:contact_tel]).to eq source_contact_group.contact_tel
              expect(contact_group[:contact_fax]).to eq source_contact_group.contact_fax
              expect(contact_group[:contact_email]).to eq source_contact_group.contact_email
              expect(contact_group[:contact_link_url]).to eq source_contact_group.contact_link_url
              expect(contact_group[:contact_link_name]).to eq source_contact_group.contact_link_name
            end
          end
        end
      end

      #
      # Delete
      #
      visit chorg_revision_path(site: site, id: revision)
      within "dd.chorg-revisions-division" do
        click_on [ new_name11, new_name2 ].join(",")
      end
      expect(page).to have_css("#chorg-after-basic1", text: new_name11)
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      revision.reload
      expect(revision.changesets).to be_blank
    end
  end
end
