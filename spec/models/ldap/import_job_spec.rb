require 'spec_helper'

describe Ldap::ImportJob, ldap: true do
  describe "#call" do
    context "when no ldap connection is set" do
      subject { Ldap::ImportJob.new }

      it "should not raise errors" do
        expect { subject.call(cms_site.id, cms_user.id, "pass") }.to raise_error
      end
    end

    context "when ldap connection is set" do
      let(:group) do
        create(:cms_group, name: unique_id, ldap_host: ENV["ldap_host"],
               ldap_dn: "dc=city,dc=shirasagi,dc=jp", ldap_auth_method: "anonymous")
      end
      let(:site) do
        create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"],
               group_ids: [group.id])
      end
      let(:role) do
        create(:cms_user_role, name: "ldap_user_role_#{unique_id}", site_id: site.id)
      end
      let(:user) do
        create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", in_password: "pass",
               group_ids: [group.id], cms_role_ids: [role.id])
      end
      subject { Ldap::ImportJob.new }

      import = nil
      it "should not raise errors" do
        expect { import = subject.call(site.id, user.id, "pass") }.not_to raise_error
      end
      it "should return non-nil" do
        expect(import).not_to be_nil
      end
    end
  end
end
