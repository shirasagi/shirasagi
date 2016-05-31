require 'spec_helper'

describe Ldap::ImportJob, dbscope: :example, ldap: true do
  describe "#perform" do
    context "when no ldap connection is set" do
      it "should raise errors" do
        described_class.perform_now(cms_site.id, cms_user.id, "pass")

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("FATAL -- : Failed Job"))
        expect(log.logs).to include(include("Net::LDAP::BindingInformationInvalidError"))
      end
    end

    context "when ldap connection is set" do
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

      around(:each) do |example|
        save_auth_method = SS.config.ldap.auth_method
        SS.config.replace_value_at(:ldap, :auth_method, "anonymous")
        example.run
        SS.config.replace_value_at(:ldap, :auth_method, save_auth_method)
      end

      import = nil
      it "should not raise errors" do
        expect { import = described_class.perform_now(site.id, user.id, "pass") }.not_to raise_error
      end
      it "should return non-nil" do
        expect(import).not_to be_nil
      end
    end
  end
end
