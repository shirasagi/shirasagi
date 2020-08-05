require 'spec_helper'

describe Gws::Chorg::TestRunner, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:task) { Gws::Chorg::Task.create!(name: unique_id, group_id: site) }
  let(:job_opts) { {} }

  context 'with add' do
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_add_changeset, revision_id: revision.id) }

    it do
      expect(revision).not_to be_nil
      expect(changeset).not_to be_nil

      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::Group.where(name: changeset.destinations.first['name']).first).to be_nil

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 1
      expect(task.entity_logs[0]['model']).to eq 'Gws::Group'
      expect(task.entity_logs[0]['creates']).to include({ 'name' => changeset.destinations.first['name'] })
    end
  end

  context 'with move' do
    let(:group) { create(:gws_revision_new_group) }
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_move_changeset, revision_id: revision.id, source: group) }

    it do
      # ensure create models
      expect(changeset).not_to be_nil

      # check for not changed
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::Group.where(id: group.id).first).not_to be_nil
      expect(Gws::Group.where(id: group.id).first.name).to eq changeset.sources.first['name']

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 1
      expect(task.entity_logs[0]['model']).to eq 'Gws::Group'
      expect(task.entity_logs[0]['id']).to eq group.id.to_s
      expect(task.entity_logs[0]['changes']).to include(
        'name', 'contact_tel', 'contact_fax', 'contact_email', 'contact_link_url', 'contact_link_name'
      )
    end
  end

  context 'with unify' do
    let(:group1) { create(:gws_revision_new_group) }
    let(:group2) { create(:gws_revision_new_group) }
    let(:user1) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
    let(:user2) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_unify_changeset, revision_id: revision.id, sources: [group1, group2]) }

    it do
      # ensure create models
      expect(user1).not_to be_nil
      expect(user2).not_to be_nil
      expect(revision).not_to be_nil
      expect(changeset).not_to be_nil

      # check for not changed
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::Group.where(id: group1.id).first).not_to be_nil
      expect(Gws::Group.where(id: group1.id).first.name).to eq group1.name
      expect(Gws::Group.where(id: group2.id).first).not_to be_nil
      expect(Gws::Group.where(id: group2.id).first.name).to eq group2.name

      user1.reload
      expect(user1.group_ids).to eq [group1.id]
      user2.reload
      expect(user2.group_ids).to eq [group2.id]

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 3
      expect(task.entity_logs[0]['model']).to eq 'Gws::Group'
      expect(task.entity_logs[0]['creates']).to include('name')
      expect(task.entity_logs[1]['model']).to eq 'Gws::Group'
      expect(task.entity_logs[1]['id']).to eq group1.id.to_s
      expect(task.entity_logs[1]['deletes']).to include('name')
      expect(task.entity_logs[2]['model']).to eq 'Gws::Group'
      expect(task.entity_logs[2]['id']).to eq group2.id.to_s
      expect(task.entity_logs[2]['deletes']).to include('name')
    end
  end

  context 'with delete' do
    let(:group) { create(:gws_revision_new_group) }
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_delete_changeset, revision_id: revision.id, source: group) }

    it do
      # ensure create models
      expect(changeset).not_to be_nil

      # change group.
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      # check for not changed
      expect(Gws::Group.where(id: group.id).first).not_to be_nil

      task.reload
      expect(task.state).to eq 'stop'
      expect(task.entity_logs.count).to eq 1
      expect(task.entity_logs[0]['model']).to eq 'Gws::Group'
      expect(task.entity_logs[0]['id']).to eq group.id.to_s
      expect(task.entity_logs[0]['deletes']).to include('name')
    end
  end
end
