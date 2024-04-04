require 'spec_helper'

describe Cms::Ldap::ImportJob, dbscope: :example, ldap: true do
  describe "#perform" do
    context "when no ldap connection is set" do
      it "should raise errors" do
        Cms::Site.find(cms_site.id).tap do |site|
          site.ldap_use_state = "individual"
          site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
          site.ldap_auth_method = "simple"
          site.save!
        end

        described_class.bind(site_id: cms_site.id, user_id: cms_user.id).perform_now

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/FATAL -- : .* Failed Job/)
        expect(log.logs).to include(include("Net::LDAP::BindingInformationInvalidError"))
      end
    end

    context "when ldap connection is set" do
      let(:group) do
        create(:cms_group, name: unique_id, ldap_dn: "dc=example,dc=jp")
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

      before do
        site.ldap_use_state = "individual"
        site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
        site.ldap_auth_method = "anonymous"
        site.save!
      end

      it "should not raise errors" do
        import = nil
        expect { import = described_class.bind(site_id: site.id, user_id: user.id).perform_now }.not_to raise_error
        expect(import).not_to be_nil
      end
    end
  end
end
