require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [ root_group.id ]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with division" do
    context "with all available attributes" do
      let!(:source_group) { create(:revision_new_group) }
      let(:destination_group1) { build(:revision_new_group) }
      let(:destination_group2) { build(:revision_new_group) }
      let!(:user) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group.id ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let!(:changeset) do
        create(
          :division_changeset, revision_id: revision.id, source: source_group,
          destinations: [ destination_group1, destination_group2 ])
      end
      let!(:source_page) { Timecop.freeze(now - 2.weeks) { create(:revision_page, cur_site: site, group: source_group) } }

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        group_after_division1 = Cms::Group.find(source_group.id).tap do |group_after_division|
          expect(group_after_division.name).not_to eq source_group.name
          expect(group_after_division.name).to eq destination_group1.name
          expect(group_after_division.order).to eq destination_group1.order
          expect(group_after_division.ldap_dn).to eq destination_group1.ldap_dn
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            source_contact0 = source_group.contact_groups[0]
            expect(contact_after_division.id).to eq source_contact0.id

            destination_contact = destination_group1.contact_groups[0]
            expect(contact_after_division.name).to eq destination_contact.name
            expect(contact_after_division.main_state).to eq destination_contact.main_state
            expect(contact_after_division.contact_group_name).to eq destination_contact.contact_group_name
            expect(contact_after_division.contact_tel).to eq destination_contact.contact_tel
            expect(contact_after_division.contact_fax).to eq destination_contact.contact_fax
            expect(contact_after_division.contact_email).to eq destination_contact.contact_email
            expect(contact_after_division.contact_link_url).to eq destination_contact.contact_link_url
            expect(contact_after_division.contact_link_name).to eq destination_contact.contact_link_name
          end
        end
        group_after_division2 = Cms::Group.find_by(name: destination_group2.name).tap do |group_after_division|
          expect(group_after_division.name).to eq destination_group2.name
          expect(group_after_division.order).to eq destination_group2.order
          expect(group_after_division.ldap_dn).to eq destination_group2.ldap_dn
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            destination_contact = destination_group2.contact_groups[0]
            expect(contact_after_division.id).to eq destination_contact.id
            expect(contact_after_division.name).to eq destination_contact.name
            expect(contact_after_division.main_state).to eq destination_contact.main_state
            expect(contact_after_division.contact_group_name).to eq destination_contact.contact_group_name
            expect(contact_after_division.contact_tel).to eq destination_contact.contact_tel
            expect(contact_after_division.contact_fax).to eq destination_contact.contact_fax
            expect(contact_after_division.contact_email).to eq destination_contact.contact_email
            expect(contact_after_division.contact_link_url).to eq destination_contact.contact_link_url
            expect(contact_after_division.contact_link_name).to eq destination_contact.contact_link_name
          end
        end

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division1.id
          contact_after_division = group_after_division1.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
          expect(page_after_division.updated.in_time_zone).to eq source_page.updated.in_time_zone
        end

        user.reload
        expect(user.group_ids).to eq [ group_after_division1.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 5

        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group.id.to_s
        expect(task.entity_logs[0]['changes']).to be_present

        expect(task.entity_logs[1]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[1]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[1]['creates']).to be_present

        expect(task.entity_logs[2]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['id']).to eq site.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')

        expect(task.entity_logs[3]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[3]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[3]['id']).to eq site.id.to_s
        expect(task.entity_logs[3]['changes']).to include('group_ids')

        expect(task.entity_logs[4]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[4]['class']).to eq 'Article::Page'
        expect(task.entity_logs[4]['id']).to eq source_page.id.to_s
        expect(task.entity_logs[4]['changes']).to include("group_ids")
      end
    end

    context "divide from existing group to existing group" do
      let!(:group1) { create(:revision_new_group) }
      let(:group2) { build(:revision_new_group) }
      let!(:user) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ group1.id ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let!(:changeset) do
        create(:division_changeset, revision_id: revision.id, source: group1, destinations: [ group1, group2 ])
      end
      let!(:source_page) { Timecop.freeze(now - 2.weeks) { create(:revision_page, cur_site: site, group: group1) } }

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        group_after_division1 = Cms::Group.find(group1.id).tap do |group_after_division|
          expect(group_after_division.name).to eq group1.name
          expect(group_after_division.order).to eq group1.order
          expect(group_after_division.ldap_dn).to eq group1.ldap_dn
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            destination_contact = group1.contact_groups[0]
            expect(contact_after_division.id).to eq destination_contact.id
            expect(contact_after_division.name).to eq destination_contact.name
            expect(contact_after_division.main_state).to eq destination_contact.main_state
            expect(contact_after_division.contact_group_name).to eq destination_contact.contact_group_name
            expect(contact_after_division.contact_tel).to eq destination_contact.contact_tel
            expect(contact_after_division.contact_fax).to eq destination_contact.contact_fax
            expect(contact_after_division.contact_email).to eq destination_contact.contact_email
            expect(contact_after_division.contact_link_url).to eq destination_contact.contact_link_url
            expect(contact_after_division.contact_link_name).to eq destination_contact.contact_link_name
          end
        end
        group_after_division2 = Cms::Group.find_by(name: group2.name).tap do |group_after_division|
          expect(group_after_division.name).to eq group2.name
          expect(group_after_division.order).to eq group2.order
          expect(group_after_division.ldap_dn).to eq group2.ldap_dn
          expect(group_after_division.contact_groups.count).to eq 1
          group_after_division.contact_groups.first.tap do |contact_after_division|
            destination_contact = group2.contact_groups[0]
            expect(contact_after_division.id).to eq destination_contact.id
            expect(contact_after_division.name).to eq destination_contact.name
            expect(contact_after_division.main_state).to eq destination_contact.main_state
            expect(contact_after_division.contact_group_name).to eq destination_contact.contact_group_name
            expect(contact_after_division.contact_tel).to eq destination_contact.contact_tel
            expect(contact_after_division.contact_fax).to eq destination_contact.contact_fax
            expect(contact_after_division.contact_email).to eq destination_contact.contact_email
            expect(contact_after_division.contact_link_url).to eq destination_contact.contact_link_url
            expect(contact_after_division.contact_link_name).to eq destination_contact.contact_link_name
          end
        end

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_division|
          expect(page_after_division.group_ids).to eq [ group_after_division1.id, group_after_division2.id ]
          expect(page_after_division.contact_group_id).to eq group_after_division1.id
          contact_after_division = group_after_division1.contact_groups[0]
          expect(page_after_division.contact_group_contact_id).to eq contact_after_division.id
          expect(page_after_division.contact_group_relation).to eq "related"
          expect(page_after_division.contact_tel).to eq contact_after_division.contact_tel
          expect(page_after_division.contact_fax).to eq contact_after_division.contact_fax
          expect(page_after_division.contact_email).to eq contact_after_division.contact_email
          expect(page_after_division.contact_link_url).to eq contact_after_division.contact_link_url
          expect(page_after_division.contact_link_name).to eq contact_after_division.contact_link_name
          expect(page_after_division.updated.in_time_zone).to eq source_page.updated.in_time_zone
        end

        user.reload
        expect(user.group_ids).to eq [ group_after_division1.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 5

        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group1.id.to_s
        expect(task.entity_logs[0]['changes']).to be_empty

        expect(task.entity_logs[1]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[1]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[1]['creates']).to be_present

        expect(task.entity_logs[2]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[2]['id']).to eq site.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')

        expect(task.entity_logs[3]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[3]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[3]['id']).to eq site.id.to_s
        expect(task.entity_logs[3]['changes']).to include('group_ids')

        expect(task.entity_logs[4]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[4]['class']).to eq 'Article::Page'
        expect(task.entity_logs[4]['id']).to eq source_page.id.to_s
        expect(task.entity_logs[4]['changes']).to include("group_ids")
      end
    end
  end
end
