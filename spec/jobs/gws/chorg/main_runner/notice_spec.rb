require 'spec_helper'

describe Gws::Chorg::MainRunner, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:task) { Gws::Chorg::Task.create!(name: unique_id, group_id: site) }
  let(:job_opts) { {} }

  let!(:user1) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group.id]) }

  # groups
  let!(:group) { create :gws_group, name: "root" }

  let!(:group1) { create :gws_group, name: "root/group1" }
  let!(:group1_sub1) { create :gws_group, name: "root/group1/sub_group1" }
  let!(:group1_sub2) { create :gws_group, name: "root/group1/sub_group2" }

  let!(:group2) { create :gws_group, name: "root/group2" }
  let!(:group2_sub1) { create :gws_group, name: "root/group2/sub_group1" }
  let!(:group2_sub2) { create :gws_group, name: "root/group2/sub_group2" }

  let!(:group3) { create :gws_group, name: "root/group3" }
  let!(:group3_sub1) { create :gws_group, name: "root/group3/sub_group1" }
  let!(:group3_sub2) { create :gws_group, name: "root/group3/sub_group2" }

  # folders
  let!(:folder) { create(:gws_notice_folder, cur_site: site, name: "root", member_group_ids: [group.id], group_ids: [group.id]) }

  let!(:folder1) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group1",
           member_group_ids: [group1.id], group_ids: [group1.id])
  end
  let!(:folder1_sub1) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group1/sub_group1",
           member_group_ids: [group1_sub1.id], group_ids: [group1_sub1.id])
  end
  let!(:folder1_sub2) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group1/sub_group2",
           member_group_ids: [group1_sub2.id], group_ids: [group1_sub2.id])
  end

  let!(:folder2) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group2",
           member_group_ids: [group2.id], group_ids: [group2.id])
  end
  let!(:folder2_sub1) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group2/sub_group1",
           member_group_ids: [group2_sub1.id], group_ids: [group2_sub1.id])
  end
  let!(:folder2_sub2) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group2/sub_group2",
           member_group_ids: [group2_sub2.id], group_ids: [group2_sub2.id])
  end

  let!(:folder3) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group3",
           member_group_ids: [group3.id], group_ids: [group3.id])
  end
  let!(:folder3_sub1) do
    create(:gws_notice_folder,
           cur_site: site, name: "root/group3/sub_group1",
           member_group_ids: [group3_sub1.id], group_ids: [group3_sub1.id])
  end
  let!(:folder3_sub2) do
    create(:gws_notice_folder, cur_site: site,
           name: "root/group3/sub_group2",
           member_group_ids: [group3_sub2.id], group_ids: [group3_sub2.id])
  end

  # notices
  let!(:post) { create(:gws_notice_post, cur_site: site, folder: folder, name: "post") }

  let!(:post1) { create(:gws_notice_post, cur_site: site, folder: folder1, name: "post1") }
  let!(:post1_sub1) { create(:gws_notice_post, cur_site: site, folder: folder1_sub1, name: "post1_sub1") }
  let!(:post1_sub2) { create(:gws_notice_post, cur_site: site, folder: folder1_sub2, name: "post1_sub2") }

  let!(:post2) { create(:gws_notice_post, cur_site: site, folder: folder2, name: "post2") }
  let!(:post2_sub1) { create(:gws_notice_post, cur_site: site, folder: folder2_sub1, name: "post2_sub1") }
  let!(:post2_sub2) { create(:gws_notice_post, cur_site: site, folder: folder2_sub2, name: "post2_sub2") }

  let!(:post3) { create(:gws_notice_post, cur_site: site, folder: folder3, name: "post3") }
  let!(:post3_sub1) { create(:gws_notice_post, cur_site: site, folder: folder3_sub1, name: "post3_sub1") }
  let!(:post3_sub2) { create(:gws_notice_post, cur_site: site, folder: folder3_sub2, name: "post3_sub2") }

  def group_to_hash(group)
    { id: group.id, name: group.name }.stringify_keys
  end

  context 'with all' do
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset) do
      create(:gws_add_changeset,
             revision_id: revision.id,
             destinations: [{ name: "root/group4" }.stringify_keys])
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      job.perform_now(revision.name, job_opts)

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      folder4 = Gws::Notice::Folder.site(site).find_by(name: "root/group4")
      expect(folder4.notices.map(&:name)).to match_array %w()
      expect(folder4.readable_setting_range).to eq "public"
      expect(folder4.member_groups.map(&:name)).to match_array %w(root/group4)
      expect(folder4.groups.map(&:name)).to match_array %w(root/group4)
    end
  end

  context 'with move' do
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset) do
      create(:gws_move_changeset,
             revision_id: revision.id,
             sources: [group_to_hash(group1)],
             destinations: [group_to_hash(group2)])
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      job.perform_now(revision.name, job_opts)

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      folder1.reload
      folder1_sub1.reload
      folder1_sub2.reload

      expect(folder1.name).to eq "root/group2"
      expect(folder1_sub1.name).to eq "root/group2/sub_group1"
      expect(folder1_sub2.name).to eq "root/group2/sub_group2"

      expect(folder1.notices.map(&:name)).to match_array %w(post1)
      expect(folder1_sub1.notices.map(&:name)).to match_array %w(post1_sub1)
      expect(folder1_sub2.notices.map(&:name)).to match_array %w(post1_sub2)

      expect(folder1.member_groups.map(&:name)).to match_array %w(root/group2)
      expect(folder1.groups.map(&:name)).to match_array %w(root/group2)

      folder2.reload
      folder2_sub1.reload
      folder2_sub2.reload

      expect(folder2.name).to match(/^backup\/group2_\d+$/)
      expect(folder2_sub1.name).to match(/^backup\/group2_\d+\/sub_group1$/)
      expect(folder2_sub2.name).to match(/^backup\/group2_\d+\/sub_group2$/)

      expect(folder2.notices.map(&:name)).to match_array %w(post2)
      expect(folder2_sub1.notices.map(&:name)).to match_array %w(post2_sub1)
      expect(folder2_sub2.notices.map(&:name)).to match_array %w(post2_sub2)

      expect(folder2.member_groups.map(&:name)).to match_array %w(root/group2)
      expect(folder2.groups.map(&:name)).to match_array %w(root/group2)

      folder3.reload
      folder3_sub1.reload
      folder3_sub2.reload

      expect(folder3.name).to eq "root/group3"
      expect(folder3_sub1.name).to eq "root/group3/sub_group1"
      expect(folder3_sub2.name).to eq "root/group3/sub_group2"

      expect(folder3.notices.map(&:name)).to match_array %w(post3)
      expect(folder3_sub1.notices.map(&:name)).to match_array %w(post3_sub1)
      expect(folder3_sub2.notices.map(&:name)).to match_array %w(post3_sub2)
    end
  end

  context 'with unify' do
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset1) do
      create(:gws_unify_changeset,
             revision_id: revision.id,
             sources: [group1],
             destinations: [{ name: "root/group2" }.stringify_keys])
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      job.perform_now(revision.name, job_opts)

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      folder1.reload
      folder1_sub1.reload
      folder1_sub2.reload

      expect(folder1.name).to match(/^backup\/group1_\d+$/)
      expect(folder1_sub1.name).to match(/^backup\/group1_\d+\/sub_group1$/)
      expect(folder1_sub2.name).to match(/^backup\/group1_\d+\/sub_group2$/)

      expect(folder1.notices.map(&:name)).to match_array %w()
      expect(folder1_sub1.notices.map(&:name)).to match_array %w()
      expect(folder1_sub2.notices.map(&:name)).to match_array %w()

      folder2.reload
      folder2_sub1.reload
      folder2_sub2.reload

      expect(folder2.name).to eq "root/group2"
      expect(folder2_sub1.name).to eq "root/group2/sub_group1"
      expect(folder2_sub2.name).to eq "root/group2/sub_group2"

      expect(folder2.notices.map(&:name)).to match_array %w(post2 post1 post1_sub1 post1_sub2)
      expect(folder2_sub1.notices.map(&:name)).to match_array %w(post2_sub1)
      expect(folder2_sub2.notices.map(&:name)).to match_array %w(post2_sub2)

      expect(folder2.member_groups.map(&:name)).to match_array %w(root/group1 root/group2)
      expect(folder2.groups.map(&:name)).to match_array %w(root/group1 root/group2)

      folder3.reload
      folder3_sub1.reload
      folder3_sub2.reload

      expect(folder3.name).to eq "root/group3"
      expect(folder3_sub1.name).to eq "root/group3/sub_group1"
      expect(folder3_sub2.name).to eq "root/group3/sub_group2"

      expect(folder3.notices.map(&:name)).to match_array %w(post3)
      expect(folder3_sub1.notices.map(&:name)).to match_array %w(post3_sub1)
      expect(folder3_sub2.notices.map(&:name)).to match_array %w(post3_sub2)
    end
  end

  context 'with unify (create new folder)' do
    let!(:group4) { create :gws_group, name: "root/group4" }

    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset1) do
      create(:gws_unify_changeset,
             revision_id: revision.id,
             sources: [group1],
             destinations: [{ name: "root/group4" }.stringify_keys])
    end
    let!(:changeset2) do
      create(:gws_unify_changeset,
             revision_id: revision.id,
             sources: [group2],
             destinations: [{ name: "root/group4" }.stringify_keys])
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      job.perform_now(revision.name, job_opts)

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      folder1.reload
      folder1_sub1.reload
      folder1_sub2.reload

      expect(folder1.name).to match(/^backup\/group1_\d+$/)
      expect(folder1_sub1.name).to match(/^backup\/group1_\d+\/sub_group1$/)
      expect(folder1_sub2.name).to match(/^backup\/group1_\d+\/sub_group2$/)

      expect(folder1.notices.map(&:name)).to match_array %w()
      expect(folder1_sub1.notices.map(&:name)).to match_array %w()
      expect(folder1_sub2.notices.map(&:name)).to match_array %w()

      folder2.reload
      folder2_sub1.reload
      folder2_sub2.reload

      expect(folder2.name).to match(/^backup\/group2_\d+$/)
      expect(folder2_sub1.name).to match(/^backup\/group2_\d+\/sub_group1$/)
      expect(folder2_sub2.name).to match(/^backup\/group2_\d+\/sub_group2$/)

      expect(folder2.notices.map(&:name)).to match_array %w()
      expect(folder2_sub1.notices.map(&:name)).to match_array %w()
      expect(folder2_sub2.notices.map(&:name)).to match_array %w()

      folder3.reload
      folder3_sub1.reload
      folder3_sub2.reload

      expect(folder3.name).to eq "root/group3"
      expect(folder3_sub1.name).to eq "root/group3/sub_group1"
      expect(folder3_sub2.name).to eq "root/group3/sub_group2"

      expect(folder3.notices.map(&:name)).to match_array %w(post3)
      expect(folder3_sub1.notices.map(&:name)).to match_array %w(post3_sub1)
      expect(folder3_sub2.notices.map(&:name)).to match_array %w(post3_sub2)

      folder4 = Gws::Notice::Folder.site(site).find_by(name: "root/group4")
      expect(folder4.notices.map(&:name)).to match_array %w(post1 post1_sub1 post1_sub2 post2 post2_sub1 post2_sub2)
      expect(folder4.readable_setting_range).to eq "public"
      expect(folder4.member_groups.map(&:name)).to match_array %w(root/group1 root/group2 root/group4)
      expect(folder4.groups.map(&:name)).to match_array %w(root/group1 root/group2 root/group4)
    end
  end

  context 'with division' do
    let!(:group4) { create :gws_group, name: "root/group4" }
    let!(:group5) { create :gws_group, name: "root/group5" }

    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset1) do
      create(:gws_division_changeset,
             revision_id: revision.id,
             sources: [group_to_hash(group1)],
             destinations: [group4, group5])
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      job.perform_now(revision.name, job_opts)

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      folder1.reload
      folder1_sub1.reload
      folder1_sub2.reload

      expect(folder1.name).to eq "root/group4"
      expect(folder1_sub1.name).to eq "root/group4/sub_group1"
      expect(folder1_sub2.name).to eq "root/group4/sub_group2"
      expect(folder1.member_groups.map(&:name)).to match_array %w(root/group1 root/group4 root/group5)
      expect(folder1.groups.map(&:name)).to match_array %w(root/group1 root/group4 root/group5)

      expect(folder1.notices.map(&:name)).to match_array %w(post1)
      expect(folder1_sub1.notices.map(&:name)).to match_array %w(post1_sub1)
      expect(folder1_sub2.notices.map(&:name)).to match_array %w(post1_sub2)

      folder2.reload
      folder2_sub1.reload
      folder2_sub2.reload

      expect(folder2.name).to eq "root/group2"
      expect(folder2_sub1.name).to eq "root/group2/sub_group1"
      expect(folder2_sub2.name).to eq "root/group2/sub_group2"

      expect(folder2.notices.map(&:name)).to match_array %w(post2)
      expect(folder2_sub1.notices.map(&:name)).to match_array %w(post2_sub1)
      expect(folder2_sub2.notices.map(&:name)).to match_array %w(post2_sub2)

      folder3.reload
      folder3_sub1.reload
      folder3_sub2.reload

      expect(folder3.name).to eq "root/group3"
      expect(folder3_sub1.name).to eq "root/group3/sub_group1"
      expect(folder3_sub2.name).to eq "root/group3/sub_group2"

      expect(folder3.notices.map(&:name)).to match_array %w(post3)
      expect(folder3_sub1.notices.map(&:name)).to match_array %w(post3_sub1)
      expect(folder3_sub2.notices.map(&:name)).to match_array %w(post3_sub2)

      folder5 = Gws::Notice::Folder.site(site).find_by(name: "root/group5")
      expect(folder5.notices.map(&:name)).to match_array %w()
      expect(folder5.readable_setting_range).to eq "public"
      expect(folder5.member_groups.map(&:name)).to match_array %w(root/group1 root/group4 root/group5)
      expect(folder5.groups.map(&:name)).to match_array %w(root/group1 root/group4 root/group5)
    end
  end

  context 'with delete' do
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset1) do
      create(:gws_delete_changeset,
             revision_id: revision.id,
             source: group1)
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      job.perform_now(revision.name, job_opts)

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      folder1.reload
      folder1_sub1.reload
      folder1_sub2.reload

      expect(folder1.name).to match(/^backup\/group1_\d+$/)
      expect(folder1_sub1.name).to match(/^backup\/group1_\d+\/sub_group1$/)
      expect(folder1_sub2.name).to match(/^backup\/group1_\d+\/sub_group2$/)

      expect(folder1.notices.map(&:name)).to match_array %w(post1)
      expect(folder1_sub1.notices.map(&:name)).to match_array %w(post1_sub1)
      expect(folder1_sub2.notices.map(&:name)).to match_array %w(post1_sub2)

      folder2.reload
      folder2_sub1.reload
      folder2_sub2.reload

      expect(folder2.name).to eq "root/group2"
      expect(folder2_sub1.name).to eq "root/group2/sub_group1"
      expect(folder2_sub2.name).to eq "root/group2/sub_group2"

      expect(folder2.notices.map(&:name)).to match_array %w(post2)
      expect(folder2_sub1.notices.map(&:name)).to match_array %w(post2_sub1)
      expect(folder2_sub2.notices.map(&:name)).to match_array %w(post2_sub2)

      folder3.reload
      folder3_sub1.reload
      folder3_sub2.reload

      expect(folder3.name).to eq "root/group3"
      expect(folder3_sub1.name).to eq "root/group3/sub_group1"
      expect(folder3_sub2.name).to eq "root/group3/sub_group2"

      expect(folder3.notices.map(&:name)).to match_array %w(post3)
      expect(folder3_sub1.notices.map(&:name)).to match_array %w(post3_sub1)
      expect(folder3_sub2.notices.map(&:name)).to match_array %w(post3_sub2)
    end
  end
end
