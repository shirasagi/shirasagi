require 'spec_helper'

describe Gws::Chorg::MainRunner, dbscope: :example do
  let(:site) { Gws::Group.find_by(name: 'シラサギ市') rescue create(:gws_group, name: 'シラサギ市') }
  let(:task) { Gws::Chorg::Task.create!(name: unique_id, group_id: site) }
  let(:job_opts) { {} }

  context 'with user csv' do
    let!(:sys_role) { create(:sys_role_general, name: '一般ユーザー') }
    let!(:title) { create(:gws_user_title, cur_site: site, code: "E100") }
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset1) { create(:gws_add_changeset, revision_id: revision.id, destinations: [{'name' => 'シラサギ市/企画政策部'}]) }
    let!(:changeset2) { create(:gws_add_changeset, revision_id: revision.id, destinations: [{'name' => 'シラサギ市/企画政策部/政策課'}]) }
    let(:csv_file_path) { "#{Rails.root}/spec/fixtures/gws/user/gws_users.csv" }

    before do
      Fs::UploadedFile.create_from_file(csv_file_path, content_type: 'text/csv') do |f|
        revision.in_user_csv_file = f
        revision.save!
      end
    end

    it do
      # before chorg, there are no users
      expect { Gws::User.find_by(uid: 'user4') }.to raise_error Mongoid::Errors::DocumentNotFound

      # execute
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 2, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      g1 = Cms::Group.find_by(name: 'シラサギ市/企画政策部')
      g2 = Cms::Group.find_by(name: 'シラサギ市/企画政策部/政策課')
      expect(g1.active?).to be_truthy
      expect(g2.active?).to be_truthy

      # after chorg, these users should be imported
      Gws::User.find_by(uid: 'user4').tap do |u|
        expect(u.name).to eq '一般ユーザー4'
        expect(u.group_ids).to include(g2.id)
      end
    end
  end
end
