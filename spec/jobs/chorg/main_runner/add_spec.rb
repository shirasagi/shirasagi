require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with add" do
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:add_changeset, revision_id: revision.id) }

    it do
      expect(changeset).not_to be_nil
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::Group.where(name: changeset.destinations.first["name"]).first).not_to be_nil

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
end
