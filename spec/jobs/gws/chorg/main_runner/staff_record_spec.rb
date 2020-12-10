require 'spec_helper'

describe Gws::Chorg::MainRunner, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:task) { Gws::Chorg::Task.create!(name: unique_id, group_id: site) }
  let(:staff_record_name) { unique_id }
  let(:staff_record_code) { (2010 + rand(10)).to_s }
  let(:job_opts) { { 'gws_staff_record' => { 'name' => staff_record_name, 'code' => staff_record_code } } }

  context 'with staff record creation' do
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_add_changeset, revision_id: revision.id) }

    it do
      expect(changeset).not_to be_nil

      # execute
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 2
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::StaffRecord::Year.site(site).count).to eq 1
      Gws::StaffRecord::Year.site(site).find_by(name: staff_record_name).tap do |y|
        expect(y.name).to eq staff_record_name
        expect(y.code).to eq staff_record_code
      end
    end
  end
end
