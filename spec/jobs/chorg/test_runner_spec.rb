require 'spec_helper'

describe Chorg::TestRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with add" do
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:add_changeset, revision_id: revision.id) }

    it do
      expect(revision).not_to be_nil
      expect(changeset).not_to be_nil
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::Group.where(name: changeset.destinations.first["name"]).first).to be_nil

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 2
      expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
      expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first["name"] })
      expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
      expect(task.entity_logs[1]['id']).to eq site.id.to_s
      expect(task.entity_logs[1]['changes']).to include('group_ids')
    end
  end

  context "with move" do
    let(:group) { create(:revision_new_group) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:move_changeset, revision_id: revision.id, source: group) }

    context "with Article::Page" do
      let(:page) { create(:revisoin_page, cur_site: site, group: group) }

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil
        # check for not changed
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.where(id: group.id).first).not_to be_nil
        expect(Cms::Group.where(id: group.id).first.name).to eq changeset.sources.first["name"]

        page.reload
        expect(page.group_ids).to eq [ group.id ]
        expect(page.contact_group_id).to eq group.id
        expect(page.contact_email).to eq group.contact_email
        expect(page.contact_tel).to eq group.contact_tel
        expect(page.contact_fax).to eq group.contact_fax
        expect(page.contact_link_url).to eq group.contact_link_url
        expect(page.contact_link_name).to eq group.contact_link_name

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 2
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['changes']).to include('name')
        expect(task.entity_logs[1]['model']).to eq 'Article::Page'
        expect(task.entity_logs[1]['id']).to eq '1'
        expect(task.entity_logs[1]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
      end
    end
  end

  context "with unify" do
    let(:group1) { create(:revision_new_group) }
    let(:group2) { create(:revision_new_group) }
    let(:user1) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
    let(:user2) { create(:cms_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:unify_changeset, revision_id: revision.id, sources: [group1, group2]) }

    context "with Article::Page" do
      let(:page) { create(:revisoin_page, cur_site: site, group: group1) }

      it do
        # ensure create models
        expect(user1).not_to be_nil
        expect(user2).not_to be_nil
        expect(revision).not_to be_nil
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil

        # check for not changed
        job = described_class.bind(site_id: site, task_id: task, user_id: user1)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.where(id: group1.id).first).not_to be_nil
        expect(Cms::Group.where(id: group1.id).first.name).to eq group1.name
        expect(Cms::Group.where(id: group2.id).first).not_to be_nil
        expect(Cms::Group.where(id: group2.id).first.name).to eq group2.name

        page.reload
        expect(page.group_ids).to eq [ group1.id ]
        expect(page.contact_group_id).to eq group1.id
        expect(page.contact_email).to eq group1.contact_email
        expect(page.contact_tel).to eq group1.contact_tel
        expect(page.contact_fax).to eq group1.contact_fax
        expect(page.contact_link_url).to eq group1.contact_link_url
        expect(page.contact_link_name).to eq group1.contact_link_name

        user1.reload
        expect(user1.group_ids).to eq [group1.id]
        user2.reload
        expect(user2.group_ids).to eq [group2.id]

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 5
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['creates']).to include('name', 'contact_email')
        expect(task.entity_logs[1]['model']).to eq 'Cms::Site'
        expect(task.entity_logs[1]['id']).to eq site.id.to_s
        expect(task.entity_logs[1]['changes']).to include('group_ids')
        expect(task.entity_logs[2]['model']).to eq 'Article::Page'
        expect(task.entity_logs[2]['id']).to eq '1'
        expect(task.entity_logs[2]['changes']).to include(
          'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
        )
        expect(task.entity_logs[3]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[3]['id']).to eq group1.id.to_s
        expect(task.entity_logs[3]['deletes']).to include('name', 'contact_email')
        expect(task.entity_logs[4]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[4]['id']).to eq group2.id.to_s
        expect(task.entity_logs[4]['deletes']).to include('name', 'contact_email')
      end
    end
  end

  context "with delete" do
    let(:group) { create(:revision_new_group) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:delete_changeset, revision_id: revision.id, source: group) }

    it do
      # ensure create models
      expect(changeset).not_to be_nil
      # change group.
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      # check for not changed
      expect(Cms::Group.where(id: group.id).first).not_to be_nil

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 1
      expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
      expect(task.entity_logs[0]['id']).to eq group.id.to_s
      expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
    end
  end
end
