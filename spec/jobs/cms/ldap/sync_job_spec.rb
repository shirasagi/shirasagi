require 'spec_helper'

describe Cms::Ldap::SyncJob, dbscope: :example do
  let(:group) { create(:cms_group, name: unique_id, ldap_dn: "dc=example,dc=jp") }
  let(:item) { create(:ldap_import) }
  subject { Cms::Ldap::SyncJob.bind(site_id: cms_site.id) }

  describe "#perform" do
    it do
      expect { @job = ss_perform_now(subject, group.id, item.id) }.not_to raise_error
      expect(@job.results).not_to be_nil

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Group.where(name: "#{group.name}/001企画政策部/001001政策課").first.tap do |group|
        expect(group.ldap_dn).to eq "ou=001001政策課,ou=001企画政策部,dc=example,dc=jp"
        expect(group.ldap_import_id).to eq item.id
        expect(group.contact_groups.count).to eq 1
        group.contact_groups.first.tap do |contact|
          expect(contact.main_state).to eq "main"
          expect(contact.name).to eq "001001政策課"
          expect(contact.contact_tel).to be_blank
          expect(contact.contact_email).to be_present
        end
      end
    end
  end
end
