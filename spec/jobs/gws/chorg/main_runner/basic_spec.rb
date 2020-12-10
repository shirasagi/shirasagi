require 'spec_helper'

describe Gws::Chorg::MainRunner, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:task) { Gws::Chorg::Task.create!(name: unique_id, group_id: site) }
  let(:job_opts) { {} }

  context 'with add' do
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_add_changeset, revision_id: revision.id) }

    it do
      expect(changeset).not_to be_nil

      # execute
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.to output(include("[新設] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.where(name: changeset.destinations.first['name']).first.active?).to be_truthy
    end
  end

  context 'with move' do
    let(:group) { create(:gws_revision_new_group) }
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_move_changeset, revision_id: revision.id, source: group) }

    context 'with usual case' do
      it do
        # ensure create models
        expect(changeset).not_to be_nil

        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Group.where(name: group.name).first).to be_nil
        expect(Gws::Group.where(id: group.id).first.name).to eq changeset.destinations.first['name']
        # ldap_dn is expected not to be changed.
        expect(Gws::Group.where(id: group.id).first.ldap_dn).to eq group.ldap_dn
      end
    end

    context 'with only move name' do
      let(:group) { create(:gws_revision_new_group) }
      let(:revision) { create(:gws_revision, site_id: site.id) }
      let(:changeset) { create(:gws_move_changeset_only_name, revision_id: revision.id, source: group) }

      it do
        # ensure create models
        expect(changeset).not_to be_nil

        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Group.where(name: group.name).first).to be_nil
        expect(Gws::Group.where(id: group.id).first.name).to eq changeset.destinations.first['name']
      end
    end
  end

  context 'with unify' do
    context 'with usual case' do
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
        expect(changeset).not_to be_nil

        # execute
        job = described_class.bind(site_id: site, user_id: user1, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Group.where(id: group1.id).first.active?).to be_falsey
        expect(Gws::Group.where(name: group1.name).first.active?).to be_falsey
        expect(Gws::Group.where(id: group2.id).first.active?).to be_falsey
        expect(Gws::Group.where(name: group2.name).first.active?).to be_falsey
        new_group = Gws::Group.where(name: changeset.destinations.first['name']).first
        expect(new_group.active?).to be_truthy

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]
      end
    end

    context 'unify to existing group' do
      let(:group1) { create(:gws_revision_new_group) }
      let(:group2) { create(:gws_revision_new_group) }
      let(:user1) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
      let(:user2) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
      let(:revision) { create(:gws_revision, site_id: site.id) }
      let(:changeset) do
        create(:gws_unify_changeset, revision_id: revision.id, sources: [group1, group2], destination: group1)
      end

      it do
        # ensure create models
        expect(user1).not_to be_nil
        expect(user2).not_to be_nil
        expect(changeset).not_to be_nil
        expect(changeset.destinations[0]['name']).to eq group1.name

        # execute
        job = described_class.bind(site_id: site, user_id: user1, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        # group1 shoud be exist because group1 is destination_group.
        expect(Gws::Group.where(id: group1.id).first.active?).to be_truthy
        expect(Gws::Group.where(name: group1.name).first.active?).to be_truthy
        # group2 shoudn't be exist because group2 is not destination_group.
        expect(Gws::Group.where(id: group2.id).first.active?).to be_falsey
        expect(Gws::Group.where(name: group2.name).first.active?).to be_falsey
        new_group = Gws::Group.where(name: changeset.destinations.first['name']).first
        expect(new_group.active?).to be_truthy
        expect(new_group.id).to eq group1.id
        expect(new_group.name).to eq group1.name

        user1.reload
        expect(user1.group_ids).to eq [new_group.id]
        user2.reload
        expect(user2.group_ids).to eq [new_group.id]
      end
    end
  end

  context 'with division' do
    context 'with usual case' do
      let(:group0) { create(:gws_revision_new_group) }
      let(:group1) { build(:gws_revision_new_group) }
      let(:group2) { build(:gws_revision_new_group) }
      let(:user) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group0.id]) }
      let(:revision) { create(:gws_revision, site_id: site.id) }
      let(:changeset) do
        create(:gws_division_changeset, revision_id: revision.id, source: group0, destinations: [group1, group2])
      end

      it do
        # ensure create models
        expect(user).not_to be_nil
        expect(changeset).not_to be_nil
        expect(page).not_to be_nil

        # execute
        job = described_class.bind(site_id: site, user_id: user, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Group.where(id: group0.id).first.active?).to be_falsey
        expect(Gws::Group.where(name: group0.name).first.active?).to be_falsey
        new_group1 = Gws::Group.where(name: changeset.destinations[0]['name']).first
        expect(new_group1.active?).to be_truthy
        new_group2 = Gws::Group.where(name: changeset.destinations[1]['name']).first
        expect(new_group2.active?).to be_truthy

        user.reload
        expect(user.group_ids).to eq [ new_group1.id ]
      end
    end

    context 'divide from existing group to existing group' do
      let(:group1) { create(:gws_revision_new_group) }
      let(:group2) { build(:gws_revision_new_group) }
      let(:user) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
      let(:revision) { create(:gws_revision, site_id: site.id) }
      let(:changeset) do
        create(:gws_division_changeset, revision_id: revision.id, source: group1, destinations: [group1, group2])
      end

      it do
        # ensure create models
        expect(user).not_to be_nil
        expect(changeset).not_to be_nil

        # execute
        job = described_class.bind(site_id: site, user_id: user, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Group.where(id: group1.id).first.active?).to be_truthy
        expect(Gws::Group.where(name: group1.name).first.active?).to be_truthy
        expect(Gws::Group.where(name: group2.name).first.active?).to be_truthy

        new_group1 = Gws::Group.where(name: changeset.destinations[0]['name']).first
        expect(new_group1.active?).to be_truthy
        new_group2 = Gws::Group.where(name: changeset.destinations[1]['name']).first
        expect(new_group2.active?).to be_truthy

        user.reload
        expect(user.group_ids).to eq [ new_group1.id ]
      end
    end
  end

  context 'with delete' do
    let(:group) { create(:gws_revision_new_group) }
    let(:revision) { create(:gws_revision, site_id: site.id) }
    let(:changeset) { create(:gws_delete_changeset, revision_id: revision.id, source: group) }

    context 'with default delete_method (disable_if_possible)' do
      it do
        # ensure create models
        expect(changeset).not_to be_nil

        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Group.where(id: group.id).first.active?).to be_falsey
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
        expect(Gws::Job::Log.count).to eq 1
        Gws::Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Gws::Group.where(id: group.id).first).to be_nil
      end
    end
  end
end
