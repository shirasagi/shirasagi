require 'spec_helper'

describe Gws::Chorg::MainRunner, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:task) { Gws::Chorg::Task.create!(name: unique_id, group_id: site) }
  let(:job_opts) { {} }

  context 'with unify' do
    let!(:group1) { create(:gws_revision_new_group) }
    let!(:group2) { create(:gws_revision_new_group) }
    let!(:user1) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group1.id]) }
    let!(:user2) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group2.id]) }
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset) { create(:gws_unify_changeset, revision_id: revision.id, sources: [group1, group2]) }
    let!(:custom_group) do
      # custom_group_ids は group_ids を部分文字列とする。
      # ここで、custom group の id を group1 の id と同じ ID に設定し、
      # 組織変更実行時に誤って変更されないことも確認する。
      create(:gws_custom_group, cur_site: site, id: group1.id, member_ids: [user1.id, user2.id], group_ids: [group1.id])
    end
    let(:cate1) do
      Gws::Board::Category.create!(cur_site: site, name: unique_id, group_ids: [group1.id])
    end
    let!(:topic) do
      Gws::Board::Topic.create!(
        cur_site: site, cur_user: user1, mode: 'thread', category_ids: [cate1.id],
        name: unique_id, text_type: 'plain', text: unique_id,
        group_ids: [group1.id], readable_group_ids: [group1.id],
        custom_group_ids: [custom_group.id], readable_custom_group_ids: [custom_group.id]
      )
    end
    let!(:post) do
      Gws::Board::Post.create!(
        cur_site: site, cur_user: user2, topic_id: topic.id, parent_id: topic.id,
        name: "Re: #{topic.name}", text_type: 'plain', text: unique_id,
        group_ids: [group1.id], custom_group_ids: [custom_group.id]
      )
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user1, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.not_to raise_error

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::Group.where(id: group1.id).first.active?).to be_falsey
      expect(Gws::Group.where(id: group2.id).first.active?).to be_falsey
      new_group = Gws::Group.where(name: changeset.destinations.first['name']).first
      expect(new_group.active?).to be_truthy

      topic.reload
      expect(topic.group_ids).to eq [new_group.id]
      expect(topic.readable_group_ids).to eq [new_group.id]
      expect(topic.custom_group_ids).to eq [custom_group.id]
      expect(topic.readable_custom_group_ids).to eq [custom_group.id]

      post.reload
      expect(post.group_ids).to eq [new_group.id]
      expect(post.custom_group_ids).to eq [custom_group.id]

      cate1.reload
      expect(cate1.group_ids).to eq [new_group.id]

      custom_group.reload
      expect(custom_group.group_ids).to eq [new_group.id]
    end
  end

  context 'with division' do
    let!(:group0) { create(:gws_revision_new_group) }
    let!(:group1) { build(:gws_revision_new_group) }
    let!(:group2) { build(:gws_revision_new_group) }
    let!(:user) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group0.id]) }
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset) do
      create(:gws_division_changeset, revision_id: revision.id, source: group0, destinations: [group1, group2])
    end
    let!(:custom_group) do
      # custom_group_ids は group_ids を部分文字列とする。
      # ここで、custom group の id を group0 の id と同じ ID に設定し、
      # 組織変更実行時に誤って変更されないことも確認する。
      create(:gws_custom_group, cur_site: site, id: group0.id, member_ids: [user.id], group_ids: [group0.id])
    end
    let(:cate1) do
      Gws::Board::Category.create!(cur_site: site, name: unique_id, group_ids: [group0.id])
    end
    let!(:topic) do
      Gws::Board::Topic.create!(
        cur_site: site, cur_user: user, mode: 'thread', category_ids: [cate1.id],
        name: unique_id, text_type: 'plain', text: unique_id,
        group_ids: [group0.id], readable_group_ids: [group0.id],
        custom_group_ids: [custom_group.id], readable_custom_group_ids: [custom_group.id]
      )
    end
    let!(:post) do
      Gws::Board::Post.create!(
        cur_site: site, cur_user: user, topic_id: topic.id, parent_id: topic.id,
        name: "Re: #{topic.name}", text_type: 'plain', text: unique_id,
        group_ids: [group0.id], custom_group_ids: [custom_group.id]
      )
    end

    it do
      # execute
      job = described_class.bind(site_id: site, user_id: user, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.not_to raise_error

      expect(Gws::Group.where(id: group0.id).first.active?).to be_falsey
      new_group1 = Cms::Group.where(name: changeset.destinations[0]['name']).first
      expect(new_group1.active?).to be_truthy
      new_group2 = Cms::Group.where(name: changeset.destinations[1]['name']).first
      expect(new_group2.active?).to be_truthy

      topic.reload
      expect(topic.group_ids).to eq [ new_group1.id, new_group2.id ]
      expect(topic.readable_group_ids).to eq [ new_group1.id, new_group2.id ]
      expect(topic.custom_group_ids).to eq [ custom_group.id ]
      expect(topic.readable_custom_group_ids).to eq [custom_group.id]

      post.reload
      expect(post.group_ids).to eq [ new_group1.id, new_group2.id ]
      expect(post.custom_group_ids).to eq [custom_group.id]

      cate1.reload
      expect(cate1.group_ids).to eq [ new_group1.id, new_group2.id ]

      custom_group.reload
      expect(custom_group.group_ids).to eq [ new_group1.id, new_group2.id ]
    end
  end

  context 'with delete' do
    let!(:group) { create(:gws_revision_new_group) }
    let!(:user) { create(:gws_user, name: unique_id.to_s, email: "#{unique_id}@example.jp", group_ids: [group.id]) }
    let!(:revision) { create(:gws_revision, site_id: site.id) }
    let!(:changeset) { create(:gws_delete_changeset, revision_id: revision.id, source: group) }
    let(:cate1) do
      Gws::Board::Category.create!(cur_site: site, name: unique_id, group_ids: [group.id])
    end
    let!(:topic) do
      Gws::Board::Topic.create!(
        cur_site: site, cur_user: user, mode: 'thread', category_ids: [cate1.id],
        name: unique_id, text_type: 'plain', text: unique_id,
        group_ids: [group.id], readable_group_ids: [group.id]
      )
    end
    let!(:post) do
      Gws::Board::Post.create!(
        cur_site: site, cur_user: user, topic_id: topic.id, parent_id: topic.id,
        name: "Re: #{topic.name}", text_type: 'plain', text: unique_id,
        group_ids: [group.id]
      )
    end

    it do
      # execute
      job = described_class.bind(site_id: site, task_id: task)
      expect { job.perform_now(revision.name, job_opts) }.not_to raise_error

      expect(Gws::Group.where(id: group.id).first.active?).to be_falsey

      # confirm that relations was not changed with delete.
      save = topic.group_ids
      topic.reload
      expect(topic.group_ids).to eq save
      expect(topic.readable_group_ids).to eq save

      save = post.group_ids
      post.reload
      expect(post.group_ids).to eq save

      save = cate1.group_ids
      cate1.reload
      expect(cate1.group_ids).to eq save
    end
  end
end
