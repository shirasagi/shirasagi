require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site.id) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  context 'with user csv' do
    let(:revision) { create(:revision, site_id: site.id) }
    let!(:changeset1) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/C'}]) }
    let!(:changeset2) { create(:add_changeset, revision_id: revision.id, destinations: [{'name' => 'A/B/D'}]) }
    let(:csv_file_path) { "#{Rails.root}/spec/fixtures/cms/user/cms_users_1.csv" }

    let!(:g1) { create(:cms_group, name: "A", order: 10) }
    let!(:g2) { create(:cms_group, name: "A/B", order: 20) }
    let!(:r1) { create(:cms_role, cur_site: site, name: "all") }
    let!(:r2) { create(:cms_role, cur_site: site, name: "edit") }

    before do
      site.add_to_set(group_ids: [g1.id, g2.id])

      Fs::UploadedFile.create_from_file(csv_file_path, content_type: 'text/csv') do |f|
        revision.in_user_csv_file = f
        revision.save!
      end
    end

    it do
      # before chorg, there are no users
      expect { Cms::User.find_by(uid: 'import_sys') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_admin') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_user1') }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { Cms::User.find_by(uid: 'import_user2') }.to raise_error Mongoid::Errors::DocumentNotFound

      job = described_class.bind(site_id: site.id, task_id: task.id)
      expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[新設] 成功: 2, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      g3 = Cms::Group.find_by(name: 'A/B/C')
      g4 = Cms::Group.find_by(name: 'A/B/D')

      # after chorg, these users should be imported
      Cms::User.find_by(uid: 'import_sys').tap do |u|
        expect(u.name).to eq 'import_sys'
        expect(u.group_ids).to include(g1.id)
        expect(u.cms_role_ids).to include(r1.id, r2.id)
      end

      Cms::User.find_by(uid: 'import_admin').tap do |u|
        expect(u.name).to eq 'import_admin'
        expect(u.group_ids).to include(g3.id)
        expect(u.cms_role_ids).to include(r1.id)
      end

      Cms::User.find_by(uid: 'import_user1').tap do |u|
        expect(u.name).to eq 'import_user1'
        expect(u.group_ids).to include(g3.id, g4.id)
        expect(u.cms_role_ids).to include(r2.id)
      end

      Cms::User.find_by(uid: 'import_user2').tap do |u|
        expect(u.name).to eq 'import_user2'
        expect(u.group_ids).to include(g4.id)
        expect(u.cms_role_ids).to include(r2.id)
      end
    end
  end
end
