require 'spec_helper'

describe "chorg_import_revision", dbscope: :example do
  let!(:site) { cms_site }
  let!(:new_path) { new_chorg_revision_path site: site.id }

  let(:group0) { create(:revision_new_group, name: "組織変更/グループ_1") }
  let(:group1) { create(:revision_new_group, name: "組織変更/グループ_2") }
  let(:group2) { create(:revision_new_group, name: "組織変更/グループ_3") }
  let(:group3) { create(:revision_new_group, name: "組織変更/グループ_4") }
  let(:group4) { create(:revision_new_group, name: "組織変更/グループ_5") }
  let(:group5) { create(:revision_new_group, name: "組織変更/グループ_6") }
  let(:group6) { create(:revision_new_group, name: "組織変更/グループ_7") }
  let(:group7) { create(:revision_new_group, name: "組織変更/グループ_8") }
  let(:group8) { create(:revision_new_group, name: "組織変更/グループ_9") }

  let!(:destination0) do
    [
      {
        "name"=>"組織変更/グループ_1",
        "order"=>"1",
        "contact_tel"=>"000-0000-0000",
        "contact_fax"=>"000-0000-0000",
        "contact_email"=>"sample1@example.jp",
        "contact_link_url"=>"http://www.ss-proj.org/",
        "contact_link_name"=>"link1",
        "ldap_dn"=>"dn1"
      }
    ]
  end

  let!(:destination1) do
    [
      {
        "name"=>"組織変更/グループ_2",
        "order"=>"2",
        "contact_tel"=>"000-0000-0000",
        "contact_fax"=>"000-0000-0000",
        "contact_email"=>"sample2@example.jp",
        "contact_link_url"=>"http://www.ss-proj.org/",
        "contact_link_name"=>"link2",
        "ldap_dn"=>"dn2"
      }
    ]
  end

  let!(:destination2) do
    [
      {
        "name"=>"組織変更/グループ_3",
        "order"=>"3",
        "contact_tel"=>"000-0000-0000",
        "contact_fax"=>"000-0000-0000",
        "contact_email"=>"sample3@example.jp",
        "contact_link_url"=>"http://www.ss-proj.org/",
        "contact_link_name"=>"link3",
        "ldap_dn"=>"dn3"
      }
    ]
  end

  let!(:destination3) do
    [
      {
        "name"=>"組織変更/グループ_4",
        "order"=>"4",
        "contact_tel"=>"000-0000-0000",
        "contact_fax"=>"000-0000-0000",
        "contact_email"=>"sample4@example.jp",
        "contact_link_url"=>"http://www.ss-proj.org/",
        "contact_link_name"=>"link4",
        "ldap_dn"=>"dn4"
      }
    ]
  end

  context "revision in new path" do
    before { login_cms_user }

    it "#download_template" do
      visit new_path
      expect(current_path).not_to eq sns_login_path

      click_on I18n.t("ss.links.download_template")

      expect(page.response_headers['Content-Type']).to eq("text/csv")
      header = CSV.parse(page.body.encode("UTF-8")).first

      expect(header).to match_array I18n.t("chorg.import.changeset").values
    end

    it 'import "add" csv' do
      visit new_path
      expect(current_path).not_to eq sns_login_path

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        attach_file "item[in_revision_csv_file]", Rails.root.join("spec", "fixtures", "chorg", "add_revision_template.csv").to_s
        click_button "保存"
      end

      expect(current_path).not_to eq new_path

      revision = Chorg::Revision.first
      expect(revision).not_to eq nil
      expect(revision.name).to eq "sample"

      changesets = revision.changesets
      expect(changesets.size).to eq 2

      expect(changesets[0].type).to eq "add"
      expect(changesets[0].sources).to eq nil
      expect(changesets[0].destinations).to match_array destination0

      expect(changesets[1].type).to eq "add"
      expect(changesets[1].sources).to eq nil
      expect(changesets[1].destinations).to match_array destination1
    end

    it 'import "move" csv' do
      group2
      group3

      visit new_path
      expect(current_path).not_to eq sns_login_path

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        attach_file "item[in_revision_csv_file]", Rails.root.join("spec", "fixtures", "chorg", "move_revision_template.csv").to_s
        click_button "保存"
      end

      expect(current_path).not_to eq new_path

      revision = Chorg::Revision.first
      expect(revision).not_to eq nil
      expect(revision.name).to eq "sample"

      changesets = revision.changesets
      expect(changesets.size).to eq 2

      expect(changesets[0].type).to eq "move"
      expect(changesets[0].sources.size).to eq 1
      expect(changesets[0].sources[0]["id"]).to eq group2.id
      expect(changesets[0].sources[0]["name"]).to eq "組織変更/グループ_3"
      expect(changesets[0].destinations).to match_array destination0

      expect(changesets[1].type).to eq "move"
      expect(changesets[1].sources.size).to eq 1
      expect(changesets[1].sources[0]["id"]).to eq group3.id
      expect(changesets[1].sources[0]["name"]).to eq "組織変更/グループ_4"
      expect(changesets[1].destinations).to match_array destination1
    end

    it 'import "unify" csv' do
      group3
      group4
      group5
      group6
      group7
      group8

      visit new_path
      expect(current_path).not_to eq sns_login_path

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        attach_file "item[in_revision_csv_file]", Rails.root.join("spec", "fixtures", "chorg", "unify_revision_template.csv").to_s
        click_button "保存"
      end

      expect(current_path).not_to eq new_path

      revision = Chorg::Revision.first
      expect(revision).not_to eq nil
      expect(revision.name).to eq "sample"

      changesets = revision.changesets
      expect(changesets.size).to eq 3

      expect(changesets[0].type).to eq "unify"
      expect(changesets[0].sources.size).to eq 3
      expect(changesets[0].sources[0]["id"]).to eq group3.id
      expect(changesets[0].sources[0]["name"]).to eq "組織変更/グループ_4"
      expect(changesets[0].sources[1]["id"]).to eq group4.id
      expect(changesets[0].sources[1]["name"]).to eq "組織変更/グループ_5"
      expect(changesets[0].sources[2]["id"]).to eq group5.id
      expect(changesets[0].sources[2]["name"]).to eq "組織変更/グループ_6"
      expect(changesets[0].destinations).to eq destination0

      expect(changesets[1].type).to eq "unify"
      expect(changesets[1].sources.size).to eq 2
      expect(changesets[1].sources[0]["id"]).to eq group6.id
      expect(changesets[1].sources[0]["name"]).to eq "組織変更/グループ_7"
      expect(changesets[1].sources[1]["id"]).to eq group7.id
      expect(changesets[1].sources[1]["name"]).to eq "組織変更/グループ_8"
      expect(changesets[1].destinations).to eq destination1

      expect(changesets[2].type).to eq "unify"
      expect(changesets[2].sources.size).to eq 1
      expect(changesets[2].sources[0]["id"]).to eq group8.id
      expect(changesets[2].sources[0]["name"]).to eq "組織変更/グループ_9"
      expect(changesets[2].destinations).to eq destination2
    end

    it 'import "division" csv' do
      group4
      group5
      group6

      visit new_path
      expect(current_path).not_to eq sns_login_path

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        attach_file "item[in_revision_csv_file]", Rails.root.join("spec", "fixtures", "chorg", "division_revision_template.csv").to_s
        click_button "保存"
      end

      expect(current_path).not_to eq new_path

      revision = Chorg::Revision.first
      expect(revision).not_to eq nil
      expect(revision.name).to eq "sample"

      changesets = revision.changesets
      expect(changesets.size).to eq 3

      expect(changesets[0].type).to eq "division"
      expect(changesets[0].sources.size).to eq 1
      expect(changesets[0].sources[0]["id"]).to eq group4.id
      expect(changesets[0].sources[0]["name"]).to eq "組織変更/グループ_5"
      expect(changesets[0].destinations).to eq (destination0 + destination1 + destination2)

      expect(changesets[1].type).to eq "division"
      expect(changesets[1].sources.size).to eq 1
      expect(changesets[1].sources[0]["id"]).to eq group5.id
      expect(changesets[1].sources[0]["name"]).to eq "組織変更/グループ_6"
      expect(changesets[1].destinations).to eq destination3

      expect(changesets[2].type).to eq "division"
      expect(changesets[2].sources.size).to eq 1
      expect(changesets[2].sources[0]["id"]).to eq group6.id
      expect(changesets[2].sources[0]["name"]).to eq "組織変更/グループ_7"
      expect(changesets[2].destinations).to eq destination3
    end

    it 'import "delete" csv' do
      group0
      group1

      visit new_path
      expect(current_path).not_to eq sns_login_path

      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        attach_file "item[in_revision_csv_file]", Rails.root.join("spec", "fixtures", "chorg", "delete_revision_template.csv").to_s
        click_button "保存"
      end

      expect(current_path).not_to eq new_path

      revision = Chorg::Revision.first
      expect(revision).not_to eq nil
      expect(revision.name).to eq "sample"

      changesets = revision.changesets
      expect(changesets.size).to eq 2

      expect(changesets[0].type).to eq "delete"
      expect(changesets[0].sources.size).to eq 1
      expect(changesets[0].sources[0]["id"]).to eq group0.id
      expect(changesets[0].sources[0]["name"]).to eq "組織変更/グループ_1"
      expect(changesets[0].destinations).to eq nil

      expect(changesets[1].type).to eq "delete"
      expect(changesets[1].sources.size).to eq 1
      expect(changesets[1].sources[0]["id"]).to eq group1.id
      expect(changesets[1].sources[0]["name"]).to eq "組織変更/グループ_2"
      expect(changesets[1].destinations).to eq nil
    end
  end
end
