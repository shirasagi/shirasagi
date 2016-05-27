require 'spec_helper'

describe "ldap_import", ldap: true, dbscope: :example do
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
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

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
        expect(page).to have_selector("aside#notice .wrap", text: I18n.t("ldap.messages.import_started"))
        expect(page).to have_selector("table.index tbody tr")
        expect(Ldap::Import.count).to eq 1
        item = Ldap::Import.last

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))

        #
        # show
        #
        click_on item.created.strftime("%Y/%m/%d %H:%M")
        expect(page).to have_css(".ldap-import-ldap dt", text: "LDAPインポート結果")

        #
        # sync
        #
        click_on "同期する"
        click_on "同期"
        expect(page).to have_selector("article#main h2", text: "同期結果")

        #
        # delete
        #
        visit index_path
        click_on item.created.strftime("%Y/%m/%d %H:%M")
        click_on "削除する"
        click_on "削除"
        expect(Ldap::Import.count).to eq 0
      end
    end
  end

  context "with non-ldap site" do
    let(:site) { cms_site }
    let(:index_path) { ldap_import_index_path site.id }
    let(:import_confirmation_path) { ldap_import_import_confirmation_path site.id }

    context "with auth" do
      around do |example|
        perform_enqueued_jobs do
          example.run
        end
      end

      it "#import" do
        login_cms_user
        visit import_confirmation_path
        expect(current_path).to eq import_confirmation_path
        within "form#item-form" do
          click_button "インポート"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).to have_selector("aside#notice .wrap", text: I18n.t("ldap.messages.import_started"))

        # job should be failed
        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("FATAL -- : Failed Job"))
        expect(log.logs).to include(include("Net::LDAP::BindingInformationInvalidError"))
      end
    end
  end
end
