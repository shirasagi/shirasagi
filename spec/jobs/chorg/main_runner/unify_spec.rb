require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let!(:root_group) { create(:revision_root_group) }
  let!(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let!(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with unify" do
    context "with all available attributes" do
      let!(:source_group1) { create(:revision_new_group, order: 10) }
      let!(:source_group2) { create(:revision_new_group, order: 20) }
      let!(:user1) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group1.id ]) }
      let!(:user2) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group2.id ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let!(:changeset) { create(:unify_changeset, revision_id: revision.id, sources: [ source_group1, source_group2 ]) }
      let!(:source_page) do
        create(:revision_page, cur_site: site, group: source_group1, group_ids: [ source_group1.id, source_group2.id ])
      end

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user1.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        expect { Cms::Group.find(source_group2.id) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group2.name) }.to raise_error Mongoid::Errors::DocumentNotFound
        group_after_unify = Cms::Group.find(source_group1.id).tap do |group_after_unify|
          destination0 = changeset.destinations[0]
          expect(group_after_unify.name).to eq destination0["name"]
          expect(group_after_unify.order.to_s).to eq destination0["order"]
          expect(group_after_unify.ldap_dn).to eq destination0["ldap_dn"]
          expect(group_after_unify.contact_groups.count).to eq 1
          group_after_unify.contact_groups.first.tap do |contact_after_unify|
            source_contact0 = source_group1.contact_groups[0]
            expect(contact_after_unify.id).to eq source_contact0.id

            destination_contact = destination0["contact_groups"][0]
            expect(contact_after_unify.name).to eq destination_contact["name"]
            expect(contact_after_unify.main_state).to eq destination_contact["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact["contact_link_name"]
          end
        end

        # check page
        Cms::Page.find(source_page.id).tap do |page_after_unify|
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          expect(page_after_unify.contact_tel).to eq group_after_unify.contact_tel
          expect(page_after_unify.contact_fax).to eq group_after_unify.contact_fax
          expect(page_after_unify.contact_email).to eq group_after_unify.contact_email
          expect(page_after_unify.contact_link_url).to eq group_after_unify.contact_link_url
          expect(page_after_unify.contact_link_name).to eq group_after_unify.contact_link_name
        end

        user1.reload
        expect(user1.group_ids).to eq([ group_after_unify.id ])
        user2.reload
        expect(user2.group_ids).to eq([ group_after_unify.id ])

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 5

        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq source_group1.id.to_s
        expect(task.entity_logs[0]['changes']).to include('name', 'contact_email')

        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')

        expect(task.entity_logs[2]['model']).to eq 'Cms::User'
        expect(task.entity_logs[2]['class']).to eq 'Cms::User'
        expect(task.entity_logs[2]['id']).to eq user2.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')

        expect(task.entity_logs[3]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[3]['class']).to eq 'Article::Page'
        expect(task.entity_logs[3]['id']).to eq '1'
        expect(task.entity_logs[3]['changes']).to include("group_ids")

        expect(task.entity_logs[4]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[4]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[4]['id']).to eq source_group2.id.to_s
        expect(task.entity_logs[4]['deletes']).to include('name', 'contact_email')
      end
    end

    context "unify to existing group" do
      let!(:source_group1) { create(:revision_new_group, order: 10) }
      let!(:source_group2) { create(:revision_new_group, order: 20) }
      let!(:destination_group) { create(:cms_group, name: "#{root_group.name}/#{unique_id}") }
      let!(:user1) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group1.id ]) }
      let!(:user2) { create(:cms_user, name: unique_id, email: unique_email, group_ids: [ source_group2.id ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let!(:changeset) do
        create(
          :unify_changeset, revision_id: revision.id, sources: [ source_group1, source_group2 ], destination: destination_group
        )
      end
      let!(:source_page1) { create(:revision_page, cur_site: site, group: source_group1) }
      let!(:source_page2) { create(:revision_page, cur_site: site, group: source_group2) }
      let!(:source_page3) { create(:revision_page, cur_site: site, group: destination_group) }

      it do
        # execute
        job = described_class.bind(site_id: site.id, task_id: task.id, user_id: user1.id)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # check group
        expect { Cms::Group.find(source_group1.id) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group1.name) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group2.id) }.to raise_error Mongoid::Errors::DocumentNotFound
        expect { Cms::Group.find(source_group2.name) }.to raise_error Mongoid::Errors::DocumentNotFound
        group_after_unify = Cms::Group.find(destination_group.id).tap do |group_after_unify|
          expect(group_after_unify.id).to eq destination_group.id
          destination0 = changeset.destinations.first
          expect(group_after_unify.name).to eq destination0["name"]

          expect(group_after_unify.contact_groups.count).to eq 2
          group_after_unify.contact_groups[0].tap do |contact_after_unify|
            source_contact0 = source_group1.contact_groups[0]
            expect(contact_after_unify.id).to eq source_contact0.id

            destination_contact = destination0["contact_groups"][0]
            expect(contact_after_unify.name).to eq destination_contact["name"]
            expect(contact_after_unify.main_state).to eq destination_contact["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact["contact_link_name"]
          end
          group_after_unify.contact_groups[1].tap do |contact_after_unify|
            source_contact0 = source_group2.contact_groups[0]
            expect(contact_after_unify.id).to eq source_contact0.id

            destination_contact = destination0["contact_groups"][1]
            expect(contact_after_unify.name).to eq destination_contact["name"]
            expect(contact_after_unify.main_state).to eq destination_contact["main_state"]
            expect(contact_after_unify.contact_group_name).to eq destination_contact["contact_group_name"]
            expect(contact_after_unify.contact_tel).to eq destination_contact["contact_tel"]
            expect(contact_after_unify.contact_fax).to eq destination_contact["contact_fax"]
            expect(contact_after_unify.contact_email).to eq destination_contact["contact_email"]
            expect(contact_after_unify.contact_link_url).to eq destination_contact["contact_link_url"]
            expect(contact_after_unify.contact_link_name).to eq destination_contact["contact_link_name"]
          end
        end

        # check page
        Cms::Page.find(source_page1.id).tap do |page_after_unify|
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          contact_after_unify = group_after_unify.contact_groups[0]
          expect(page_after_unify.contact_group_contact_id).to eq contact_after_unify.id
          expect(page_after_unify.contact_group_relation).to eq "related"
          expect(page_after_unify.contact_tel).to eq contact_after_unify.contact_tel
          expect(page_after_unify.contact_fax).to eq contact_after_unify.contact_fax
          expect(page_after_unify.contact_email).to eq contact_after_unify.contact_email
          expect(page_after_unify.contact_link_url).to eq contact_after_unify.contact_link_url
          expect(page_after_unify.contact_link_name).to eq contact_after_unify.contact_link_name
        end
        Cms::Page.find(source_page2.id).tap do |page_after_unify|
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          contact_after_unify = group_after_unify.contact_groups[1]
          expect(page_after_unify.contact_group_contact_id).to eq contact_after_unify.id
          expect(page_after_unify.contact_group_relation).to eq "related"
          expect(page_after_unify.contact_tel).to eq contact_after_unify.contact_tel
          expect(page_after_unify.contact_fax).to eq contact_after_unify.contact_fax
          expect(page_after_unify.contact_email).to eq contact_after_unify.contact_email
          expect(page_after_unify.contact_link_url).to eq contact_after_unify.contact_link_url
          expect(page_after_unify.contact_link_name).to eq contact_after_unify.contact_link_name
        end
        Cms::Page.find(source_page3.id).tap do |page_after_unify|
          expect(page_after_unify.group_ids).to eq [ group_after_unify.id ]
          expect(page_after_unify.contact_group_id).to eq group_after_unify.id
          expect(page_after_unify.contact_group_contact_id).to be_blank
          expect(page_after_unify.contact_group_relation).to be_blank
          expect(page_after_unify.contact_charge).to be_blank
          expect(page_after_unify.contact_tel).to be_blank
          expect(page_after_unify.contact_fax).to be_blank
          expect(page_after_unify.contact_email).to be_blank
          expect(page_after_unify.contact_link_url).to be_blank
          expect(page_after_unify.contact_link_name).to be_blank
        end

        user1.reload
        expect(user1.group_ids).to eq [ group_after_unify.id ]
        user2.reload
        expect(user2.group_ids).to eq [ group_after_unify.id ]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 9
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq destination_group.id.to_s
        expect(task.entity_logs[0]['changes']).to be_present
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
        expect(task.entity_logs[2]['model']).to eq 'Cms::User'
        expect(task.entity_logs[2]['id']).to eq user1.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')
        expect(task.entity_logs[3]['model']).to eq 'Cms::User'
        expect(task.entity_logs[3]['id']).to eq user2.id.to_s
        expect(task.entity_logs[3]['changes']).to include('group_ids')

        expect(task.entity_logs[-2]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[-2]['id']).to eq source_group1.id.to_s
        expect(task.entity_logs[-2]['deletes']).to be_present
        expect(task.entity_logs[-1]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[-1]['id']).to eq source_group2.id.to_s
        expect(task.entity_logs[-1]['deletes']).to be_present
      end
    end
  end
end
