require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with unify" do
    context "with Article::Page" do
      let(:group1) { create(:revision_new_group) }
      let(:group2) { create(:revision_new_group) }
      let(:user1) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
      let(:user2) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) { create(:unify_changeset, revision_id: revision.id, sources: [group1, group2]) }
      let(:page) { create(:revision_page, cur_site: site, group: group1) }

      it do
        # ensure create models
        expect(user1).not_to be_nil
        expect(user2).not_to be_nil
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user1)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.where(id: group1.id).first).to be_nil
        expect(Cms::Group.where(name: group1.name).first).to be_nil
        expect(Cms::Group.where(id: group2.id).first).to be_nil
        expect(Cms::Group.where(name: group2.name).first).to be_nil
        new_group = Cms::Group.where(name: changeset.destinations.first["name"]).first
        expect(new_group).not_to be_nil
        # check page
        page.reload
        expect(page.group_ids).to eq [ new_group.id ]
        expect(page.contact_group_id).to eq new_group.id
        expect(page.contact_email).to eq new_group.contact_email
        expect(page.contact_tel).to eq new_group.contact_tel
        expect(page.contact_fax).to eq new_group.contact_fax
        expect(page.contact_link_url).to eq new_group.contact_link_url
        expect(page.contact_link_name).to eq new_group.contact_link_name

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 7

        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include('name', 'contact_email')

        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')

        expect(task.entity_logs[2]['model']).to eq 'Cms::User'
        expect(task.entity_logs[2]['class']).to eq 'Cms::User'
        expect(task.entity_logs[2]['id']).to eq user1.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')

        expect(task.entity_logs[3]['model']).to eq 'Cms::User'
        expect(task.entity_logs[3]['class']).to eq 'Cms::User'
        expect(task.entity_logs[3]['id']).to eq user2.id.to_s
        expect(task.entity_logs[3]['changes']).to include('group_ids')

        expect(task.entity_logs[4]['model']).to eq 'Cms::Page'
        expect(task.entity_logs[4]['class']).to eq 'Article::Page'
        expect(task.entity_logs[4]['id']).to eq '1'
        expect(task.entity_logs[4]['changes']).to include("group_ids")

        expect(task.entity_logs[5]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[5]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[5]['id']).to eq group1.id.to_s
        expect(task.entity_logs[5]['deletes']).to include('name', 'contact_email')

        expect(task.entity_logs[6]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[6]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[6]['id']).to eq group2.id.to_s
        expect(task.entity_logs[6]['deletes']).to include('name', 'contact_email')
      end
    end

    context "unify to existing group" do
      let(:group1) { create(:revision_new_group, contact_groups: [{ contact_email: "foobar02@example.jp", main_state: "main" }]) }
      let(:group2) { create(:revision_new_group, contact_groups: [{ contact_email: "foobar@example.jp", main_state: "main" }]) }
      let(:user1) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
      let(:user2) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
      let(:revision) { create(:revision, site_id: site.id) }
      let(:changeset) do
        create(:unify_changeset, revision_id: revision.id, sources: [group1, group2], destination: group1)
      end
      let(:page) { create(:revision_page, cur_site: site, group: group1) }

      it do
        # ensure create models
        expect(user1).not_to be_nil
        expect(user2).not_to be_nil
        expect(changeset).not_to be_nil
        expect(changeset.destinations[0]["name"]).to eq group1.name
        expect(changeset.destinations[0]["contact_email"]).to eq group1.contact_email
        expect(changeset.destinations[0]["contact_tel"]).to eq group1.contact_tel
        expect(changeset.destinations[0]["contact_fax"]).to eq group1.contact_fax
        expect(changeset.destinations[0]["contact_link_url"]).to eq group1.contact_link_url
        expect(changeset.destinations[0]["contact_link_name"]).to eq group1.contact_link_name
        expect(page).not_to be_nil
        expect(page.contact_email).to eq "foobar02@example.jp"
        # execute
        job = described_class.bind(site_id: site, task_id: task, user_id: user1)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # group1 shoud be exist because group1 is destination_group.
        expect(Cms::Group.where(id: group1.id).first).not_to be_nil
        expect(Cms::Group.where(name: group1.name).first).not_to be_nil
        # group2 shoudn't be exist because group2 is not destination_group.
        expect(Cms::Group.where(id: group2.id).first).to be_nil
        expect(Cms::Group.where(name: group2.name).first).to be_nil
        new_group = Cms::Group.where(name: changeset.destinations.first["name"]).first
        expect(new_group.id).to eq group1.id
        expect(new_group.name).to eq group1.name
        # check page
        page.reload
        expect(page.group_ids).to eq [ new_group.id ]
        expect(page.contact_group_id).to eq new_group.id
        expect(page.contact_email).to eq new_group.contact_email
        expect(page.contact_email).to eq "foobar02@example.jp"
        expect(page.contact_tel).to eq new_group.contact_tel
        expect(page.contact_fax).to eq new_group.contact_fax
        expect(page.contact_link_url).to eq new_group.contact_link_url
        expect(page.contact_link_name).to eq new_group.contact_link_name

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]

        task.reload
        expect(task.state).to eq 'completed'
        expect(task.entity_logs.count).to eq 4
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group1.id.to_s
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['class']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
        expect(task.entity_logs[2]['model']).to eq 'Cms::User'
        expect(task.entity_logs[2]['id']).to eq user2.id.to_s
        expect(task.entity_logs[2]['changes']).to include('group_ids')
        expect(task.entity_logs[3]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[3]['id']).to eq group2.id.to_s
        expect(task.entity_logs[3]['deletes']).to include('name', 'contact_email')
      end
    end
  end
end
