require 'spec_helper'

describe Ldap::SyncJob, dbscope: :example do
  let(:group) { create(:cms_group, name: unique_id, ldap_dn: "dc=city,dc=shirasagi,dc=jp") }
  let(:item) { create(:ldap_import) }
  subject { Ldap::SyncJob.bind(site_id: cms_site) }

  describe "#perform" do
    it do
      expect { @job = subject.perform_now(group.id, item.id) }.not_to raise_error
      expect(@job.results).not_to be_nil
    end
  end
end
