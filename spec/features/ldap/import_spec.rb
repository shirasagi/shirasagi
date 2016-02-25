require 'spec_helper'

describe "ldap_import", ldap: true do
  context "with ldap site" do
    let(:group) do
      create(:cms_group, name: unique_id, ldap_dn: "dc=city,dc=shirasagi,dc=jp")
    end
    let(:site) do
      create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"],
             group_ids: [group.id])
    end
    let(:role) do
      create(:cms_role_admin, name: "ldap_user_role_#{unique_id}", site_id: site.id)
    end
    let(:user) do
      create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "pass",
             group_ids: [group.id], cms_role_ids: [role.id])
    end
    let(:index_path) { ldap_import_index_path site.id }
    let(:import_confirmation_path) { ldap_import_import_confirmation_path site.id }

    around(:each) do |example|
      save_auth_method = SS.config.ldap.auth_method
      SS.config.replace_value_at(:ldap, :auth_method, "anonymous")
      example.run
      SS.config.replace_value_at(:ldap, :auth_method, save_auth_method)
    end

    it "without login" do
      visit index_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end

    context "with auth" do
      it "#index" do
        login_user(user)
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end

      it "#import" do
        login_user(user)
        visit import_confirmation_path
        expect(current_path).to eq import_confirmation_path
        within "form#item-form" do
          click_button "インポート"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_selector("table.index tbody tr")
      end

      context "with item" do
        let(:item) { Ldap::Import.last }
        let(:show_path) { ldap_import_path site.id, item }
        let(:sync_confirmation_path) { "/.s#{site.id}/ldap/import/sync_confirmation/#{item.id}" }
        let(:sync_path) { "/.s#{site.id}/ldap/import/sync/#{item.id}" }
        let(:results_path) { "/.s#{site.id}/ldap/import/results/#{item.id}" }
        let(:delete_path) { delete_ldap_import_path site.id, item }

        it "#show" do
          login_user(user)
          visit show_path
          expect(status_code).to eq 200
          expect(current_path).to eq show_path
        end

        it "#sync" do
          login_user(user)
          visit sync_confirmation_path
          expect(status_code).to eq 200
          expect(current_path).to eq sync_confirmation_path
          within "form" do
            click_button "同期"
          end
          expect(status_code).to eq 200
          expect(current_path).to eq results_path
          expect(page).to have_selector("article#main div dl.see")
        end

        it "#delete" do
          login_user(user)
          visit delete_path
          expect(status_code).to eq 200
          expect(current_path).to eq delete_path
          within "form" do
            click_button "削除"
          end
          expect(status_code).to eq 200
          expect(current_path).to eq index_path
        end
      end
    end
  end

  context "with non-ldap site" do
    let(:site) { cms_site }
    let(:import_confirmation_path) { ldap_import_import_confirmation_path site.id }
    let(:import_path) { ldap_import_import_path site.id }

    context "with auth" do
      it "#import" do
        login_cms_user
        visit import_confirmation_path
        expect(current_path).to eq import_confirmation_path
        within "form#item-form" do
          click_button "インポート"
        end
        expect(status_code).to eq 400
        expect(current_path).to eq import_path
        expect(page).to have_selector("div#errorSyntaxChecker h2")
        expect(page).to have_selector("div#errorSyntaxChecker ul")
      end
    end
  end
end
