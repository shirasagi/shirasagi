require 'spec_helper'

describe "chorg_import_revision", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:revision) { create(:revision, cur_site: site) }
  let!(:group0) { create(:revision_root_group) }

  before do
    site.add_to_set(group_ids: group0.id)
    login_cms_user
  end

  describe "#import_changesets" do
    context 'import "add" csv' do
      let!(:group1) { create(:revision_new_group, name: "#{group0.name}/グループ_1") }
      let!(:group2) { create(:revision_new_group, name: "#{group0.name}/グループ_2") }

      it do
        visit chorg_revision_path(site: site, id: revision)
        click_on I18n.t("ss.links.import_csv")
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/chorg/add_revision_template.csv"
          page.accept_confirm(I18n.t("ss.confirm.import")) do
            click_on I18n.t('ss.buttons.import')
          end
        end
        wait_for_notice I18n.t("ss.notice.imported")

        revision.reload
        changesets = revision.changesets
        expect(changesets.size).to eq 2

        expect(changesets[0].type).to eq "add"
        expect(changesets[0].sources).to eq nil
        expect(changesets[0].destinations).to have(1).items
        changesets[0].destinations.first.tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_1"
          expect(destination[:order]).to eq "1"
          expect(destination[:ldap_dn]).to eq "dn1"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to be_blank
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 1"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample1@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link1"
          end
        end

        expect(changesets[1].type).to eq "add"
        expect(changesets[1].sources).to eq nil
        expect(changesets[1].destinations).to have(1).items
        changesets[1].destinations.first.tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_2"
          expect(destination[:order]).to eq "2"
          expect(destination[:ldap_dn]).to eq "dn2"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to be_blank
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 2"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample2@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link2"
          end
        end
      end
    end

    context 'import "move" csv' do
      let!(:group3) { create(:revision_new_group, name: "#{group0.name}/グループ_3") }
      let!(:group4) { create(:revision_new_group, name: "#{group0.name}/グループ_4") }

      it do
        visit chorg_revision_path(site: site, id: revision)
        click_on I18n.t("ss.links.import_csv")
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/chorg/move_revision_template.csv"
          page.accept_confirm(I18n.t("ss.confirm.import")) do
            click_on I18n.t('ss.buttons.import')
          end
        end
        wait_for_notice I18n.t("ss.notice.imported")

        revision.reload
        changesets = revision.changesets
        expect(changesets.size).to eq 2

        expect(changesets[0].type).to eq "move"
        expect(changesets[0].sources.size).to eq 1
        expect(changesets[0].sources[0]["id"]).to eq group3.id
        expect(changesets[0].sources[0]["name"]).to eq group3.name
        expect(changesets[1].destinations).to have(1).items
        changesets[0].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_1"
          expect(destination[:order]).to eq "1"
          expect(destination[:ldap_dn]).to eq "dn1"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to eq group3.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 1"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample1@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link1"
          end
        end

        expect(changesets[1].type).to eq "move"
        expect(changesets[1].sources.size).to eq 1
        expect(changesets[1].sources[0]["id"]).to eq group4.id
        expect(changesets[1].sources[0]["name"]).to eq group4.name
        expect(changesets[1].destinations).to have(1).items
        changesets[1].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_2"
          expect(destination[:order]).to eq "2"
          expect(destination[:ldap_dn]).to eq "dn2"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to eq group4.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 2"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample2@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link2"
          end
        end
      end
    end

    context 'import "unify" csv' do
      let!(:group4) { create(:revision_new_group, name: "#{group0.name}/グループ_4", order: 40) }
      let!(:group5) { create(:revision_new_group, name: "#{group0.name}/グループ_5", order: 50) }
      let!(:group6) { create(:revision_new_group, name: "#{group0.name}/グループ_6", order: 60) }
      let!(:group7) { create(:revision_new_group, name: "#{group0.name}/グループ_7", order: 70) }
      let!(:group8) { create(:revision_new_group, name: "#{group0.name}/グループ_8", order: 80) }
      let!(:group9) { create(:revision_new_group, name: "#{group0.name}/グループ_9", order: 90) }

      it do
        visit chorg_revision_path(site: site, id: revision)
        click_on I18n.t("ss.links.import_csv")
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/chorg/unify_revision_template.csv"
          page.accept_confirm(I18n.t("ss.confirm.import")) do
            click_on I18n.t('ss.buttons.import')
          end
        end
        wait_for_notice I18n.t("ss.notice.imported")

        revision.reload
        changesets = revision.changesets
        expect(changesets.size).to eq 3

        expect(changesets[0].type).to eq "unify"
        expect(changesets[0].sources.size).to eq 3
        expect(changesets[0].sources[0]["id"]).to eq group4.id
        expect(changesets[0].sources[0]["name"]).to eq group4.name
        expect(changesets[0].sources[1]["id"]).to eq group5.id
        expect(changesets[0].sources[1]["name"]).to eq group5.name
        expect(changesets[0].sources[2]["id"]).to eq group6.id
        expect(changesets[0].sources[2]["name"]).to eq group6.name
        expect(changesets[0].destinations).to have(1).items
        changesets[0].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_1"
          expect(destination[:order]).to eq "1"
          expect(destination[:ldap_dn]).to eq "dn1"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            # contact_group[:_id] にも最も優先度の高いグループがもつ同識別名の連絡先IDがセットされる
            expect(contact_group[:_id]).to eq group4.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 1"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample1@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link1"
          end
        end

        expect(changesets[1].type).to eq "unify"
        expect(changesets[1].sources.size).to eq 2
        expect(changesets[1].sources[0]["id"]).to eq group7.id
        expect(changesets[1].sources[0]["name"]).to eq group7.name
        expect(changesets[1].sources[1]["id"]).to eq group8.id
        expect(changesets[1].sources[1]["name"]).to eq group8.name
        expect(changesets[1].destinations).to have(1).items
        changesets[1].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_2"
          expect(destination[:order]).to eq "2"
          expect(destination[:ldap_dn]).to eq "dn2"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            # contact_group[:_id] にも最も優先度の高いグループがもつ同識別名の連絡先IDがセットされる
            expect(contact_group[:_id]).to eq group7.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 2"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample2@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link2"
          end
        end

        expect(changesets[2].type).to eq "unify"
        expect(changesets[2].sources.size).to eq 1
        expect(changesets[2].sources[0]["id"]).to eq group9.id
        expect(changesets[2].sources[0]["name"]).to eq group9.name
        expect(changesets[2].destinations).to have(1).items
        changesets[2].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_3"
          expect(destination[:order]).to eq "3"
          expect(destination[:ldap_dn]).to eq "dn3"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to eq group9.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 3"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample3@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link3"
          end
        end
      end
    end

    context 'import "division" csv' do
      let!(:group5) { create(:revision_new_group, name: "#{group0.name}/グループ_5", order: 50) }
      let!(:group6) { create(:revision_new_group, name: "#{group0.name}/グループ_6", order: 60) }
      let!(:group7) { create(:revision_new_group, name: "#{group0.name}/グループ_7", order: 70) }

      it do
        visit chorg_revision_path(site: site, id: revision)
        click_on I18n.t("ss.links.import_csv")
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/chorg/division_revision_template.csv"
          page.accept_confirm(I18n.t("ss.confirm.import")) do
            click_on I18n.t('ss.buttons.import')
          end
        end
        wait_for_notice I18n.t("ss.notice.imported")

        revision.reload
        changesets = revision.changesets
        expect(changesets.size).to eq 3

        expect(changesets[0].type).to eq "division"
        expect(changesets[0].sources.size).to eq 1
        expect(changesets[0].sources[0]["id"]).to eq group5.id
        expect(changesets[0].sources[0]["name"]).to eq group5.name
        expect(changesets[0].destinations).to have(3).items
        changesets[0].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_1"
          expect(destination[:order]).to eq "1"
          expect(destination[:ldap_dn]).to eq "dn1"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to eq group5.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 1"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample1@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link1"
          end
        end
        changesets[0].destinations[1].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_2"
          expect(destination[:order]).to eq "2"
          expect(destination[:ldap_dn]).to eq "dn2"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to be_blank
            expect(contact_group[:main_state]).to be_blank
            expect(contact_group[:name]).to eq "グループ 2"
            expect(contact_group[:contact_group_name]).to eq "グループ 2"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample2@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link2"
          end
        end
        changesets[0].destinations[2].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_3"
          expect(destination[:order]).to eq "3"
          expect(destination[:ldap_dn]).to eq "dn3"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to be_blank
            expect(contact_group[:main_state]).to be_blank
            expect(contact_group[:name]).to eq "グループ 3"
            expect(contact_group[:contact_group_name]).to eq "グループ 3"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample3@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link3"
          end
        end

        expect(changesets[1].type).to eq "division"
        expect(changesets[1].sources.size).to eq 1
        expect(changesets[1].sources[0]["id"]).to eq group6.id
        expect(changesets[1].sources[0]["name"]).to eq group6.name
        expect(changesets[1].destinations).to have(1).items
        changesets[1].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_4"
          expect(destination[:order]).to eq "4"
          expect(destination[:ldap_dn]).to eq "dn4"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to eq group6.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 4"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample4@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link4"
          end
        end

        expect(changesets[2].type).to eq "division"
        expect(changesets[2].sources.size).to eq 1
        expect(changesets[2].sources[0]["id"]).to eq group7.id
        expect(changesets[2].sources[0]["name"]).to eq group7.name
        expect(changesets[2].destinations).to have(1).items
        changesets[2].destinations[0].tap do |destination|
          expect(destination[:name]).to eq "組織変更/グループ_4"
          expect(destination[:order]).to eq "4"
          expect(destination[:ldap_dn]).to eq "dn4"
          expect(destination[:contact_groups]).to have(1).items
          destination[:contact_groups].first.tap do |contact_group|
            expect(contact_group[:_id]).to eq group7.contact_groups[0].id.to_s
            expect(contact_group[:main_state]).to eq "main"
            expect(contact_group[:name]).to eq "main"
            expect(contact_group[:contact_group_name]).to eq "グループ 4"
            expect(contact_group[:contact_tel]).to eq "000-0000-0000"
            expect(contact_group[:contact_fax]).to eq "000-0000-0000"
            expect(contact_group[:contact_email]).to eq "sample4@example.jp"
            expect(contact_group[:contact_postal_code]).to eq "0000000"
            expect(contact_group[:contact_address]).to eq "大鷺県シラサギ市小鷺町1丁目1番地1号"
            expect(contact_group[:contact_link_url]).to eq "http://www.ss-proj.org/"
            expect(contact_group[:contact_link_name]).to eq "link4"
          end
        end
      end
    end

    context 'import "delete" csv' do
      let!(:group1) { create(:revision_new_group, name: "#{group0.name}/グループ_1") }
      let!(:group2) { create(:revision_new_group, name: "#{group0.name}/グループ_2") }

      it do
        visit chorg_revision_path(site: site, id: revision)
        click_on I18n.t("ss.links.import_csv")
        within "form#item-form" do
          attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/chorg/delete_revision_template.csv"
          page.accept_confirm(I18n.t("ss.confirm.import")) do
            click_on I18n.t('ss.buttons.import')
          end
        end
        wait_for_notice I18n.t("ss.notice.imported")

        revision.reload
        changesets = revision.changesets
        expect(changesets.size).to eq 2

        expect(changesets[0].type).to eq "delete"
        expect(changesets[0].sources.size).to eq 1
        expect(changesets[0].sources[0]["id"]).to eq group1.id
        expect(changesets[0].sources[0]["name"]).to eq group1.name
        expect(changesets[0].destinations).to be_blank

        expect(changesets[1].type).to eq "delete"
        expect(changesets[1].sources.size).to eq 1
        expect(changesets[1].sources[0]["id"]).to eq group2.id
        expect(changesets[1].sources[0]["name"]).to eq group2.name
        expect(changesets[1].destinations).to be_blank
      end
    end
  end
end
