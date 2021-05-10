require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context "with delete" do
    let(:group) { create(:revision_new_group) }
    let(:revision) { create(:revision, site_id: site.id) }
    let(:changeset) { create(:delete_changeset, revision_id: revision.id, source: group) }

    context 'with default delete_method (disable_if_possible)' do
      it do
        # ensure create models
        expect(changeset).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.unscoped.where(id: group.id).first.active?).to be_falsey

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
      end
    end

    context 'with always_delete' do
      before do
        revision.delete_method = 'always_delete'
        revision.save!
      end

      it do
        # ensure create models
        expect(changeset).not_to be_nil
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::Group.unscoped.where(id: group.id).first).to be_nil

        task.reload
        expect(task.state).to eq 'stop'
        expect(task.entity_logs.count).to eq 1
        expect(task.entity_logs[0]['model']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['class']).to eq 'Cms::Group'
        expect(task.entity_logs[0]['id']).to eq group.id.to_s
        expect(task.entity_logs[0]['deletes']).to include('name', 'contact_email')
      end
    end
  end
end
