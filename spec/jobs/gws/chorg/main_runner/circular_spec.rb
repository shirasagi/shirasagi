require 'spec_helper'

describe Gws::Chorg::MainRunner, dbscope: :example do
  let(:site) { create(:gws_group) }
  let(:task) { Gws::Chorg::Task.create!(name: unique_id, group: site) }
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:job_opts) { {} }

  context 'with unify' do
    let!(:group1) { create(:gws_revision_new_group, order: 10) }
    let!(:group2) { create(:gws_revision_new_group, order: 20) }
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
      Gws::Circular::Category.create!(cur_site: site, name: unique_id, group_ids: [group1.id])
    end
    let!(:post) do
      Timecop.freeze(now - 3.days) do
        Gws::Circular::Post.create!(
          cur_site: site, cur_user: user1, name: unique_id, due_date: now + 3.weeks, see_type: "normal",
          text_type: 'plain', text: unique_id, category_ids: [cate1.id],
          member_group_ids: [group1.id], member_custom_group_ids: [custom_group.id],
          group_ids: [group1.id], custom_group_ids: [custom_group.id]
        )
      end
    end
    let!(:comment) do
      Timecop.freeze(now - 2.days) do
        Gws::Circular::Comment.create!(
          cur_site: site, cur_user: user2, post: post, name: "Re: #{post.name}", text: unique_id,
          group_ids: [group1.id], custom_group_ids: [custom_group.id]
        )
      end
    end

    it do
      # execute
      job = described_class.bind(site_id: site.id, user_id: user1.id, task_id: task.id)
      expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[統合] 成功: 1, 失敗: 0\n")).to_stdout

      # check for job was succeeded
      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.where(id: group1.id).first.active?).to be_truthy
      expect(Gws::Group.where(id: group2.id).first.active?).to be_falsey
      new_group = Gws::Group.where(name: changeset.destinations.first['name']).first
      expect(new_group.active?).to be_truthy
      expect(new_group.id).to eq group1.id

      Gws::Circular::Post.find(post.id).tap do |post_after_chorg|
        expect(post_after_chorg.member_group_ids).to eq [new_group.id]
        expect(post_after_chorg.member_custom_group_ids).to eq [custom_group.id]
        expect(post_after_chorg.group_ids).to eq [new_group.id]
        expect(post_after_chorg.custom_group_ids).to eq [custom_group.id]
        expect(post_after_chorg.updated).to eq post.updated
        expect(post_after_chorg.created).to eq post.created
      end

      Gws::Circular::Comment.find(comment.id).tap do |comment_after_chorg|
        expect(comment_after_chorg.group_ids).to eq [new_group.id]
        expect(comment_after_chorg.custom_group_ids).to eq [custom_group.id]
        expect(comment_after_chorg.updated).to eq comment.updated
        expect(comment_after_chorg.created).to eq comment.created
      end

      cate1.reload
      expect(cate1.group_ids).to eq [new_group.id]

      custom_group.reload
      expect(custom_group.group_ids).to eq [new_group.id]
    end
  end

  context 'with division' do
    let!(:group0) { create(:gws_revision_new_group, order: 10) }
    let!(:group1) { build(:gws_revision_new_group, order: 20) }
    let!(:group2) { build(:gws_revision_new_group, order: 30) }
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
      Gws::Circular::Category.create!(cur_site: site, name: unique_id, group_ids: [group0.id])
    end
    let!(:post) do
      Timecop.freeze(now - 3.days) do
        Gws::Circular::Post.create!(
          cur_site: site, cur_user: user, name: unique_id, due_date: now + 3.weeks, see_type: "normal",
          text_type: 'plain', text: unique_id, category_ids: [cate1.id],
          member_group_ids: [group0.id], member_custom_group_ids: [custom_group.id],
          group_ids: [group0.id], custom_group_ids: [custom_group.id]
        )
      end
    end
    let!(:comment) do
      Timecop.freeze(now - 2.days) do
        Gws::Circular::Comment.create!(
          cur_site: site, cur_user: user, post: post, name: "Re: #{post.name}", text: unique_id,
          group_ids: [group0.id], custom_group_ids: [custom_group.id]
        )
      end
    end

    it do
      # execute
      job = described_class.bind(site_id: site.id, user_id: user.id, task_id: task.id)
      expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[分割] 成功: 1, 失敗: 0\n")).to_stdout

      expect(Gws::Group.where(id: group0.id).first.active?).to be_truthy
      new_group1 = Cms::Group.where(name: changeset.destinations[0]['name']).first
      expect(new_group1.active?).to be_truthy
      expect(new_group1.id).to eq group0.id
      new_group2 = Cms::Group.where(name: changeset.destinations[1]['name']).first
      expect(new_group2.active?).to be_truthy

      Gws::Circular::Post.find(post.id).tap do |post_after_chorg|
        expect(post_after_chorg.member_group_ids).to eq [ new_group1.id, new_group2.id ]
        expect(post_after_chorg.member_custom_group_ids).to eq [custom_group.id]
        expect(post_after_chorg.group_ids).to eq [ new_group1.id, new_group2.id ]
        expect(post_after_chorg.custom_group_ids).to eq [ custom_group.id ]
        expect(post_after_chorg.updated).to eq post.updated
        expect(post_after_chorg.created).to eq post.created
      end

      Gws::Circular::Comment.find(comment.id).tap do |comment_after_chorg|
        expect(comment_after_chorg.group_ids).to eq [ new_group1.id, new_group2.id ]
        expect(comment_after_chorg.custom_group_ids).to eq [custom_group.id]
        expect(comment_after_chorg.updated).to eq comment.updated
        expect(comment_after_chorg.created).to eq comment.created
      end

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
      Gws::Circular::Category.create!(cur_site: site, name: unique_id, group_ids: [group.id])
    end
    let!(:post) do
      Timecop.freeze(now - 3.days) do
        Gws::Circular::Post.create!(
          cur_site: site, cur_user: user, name: unique_id, due_date: now + 3.weeks, see_type: "normal",
          text_type: 'plain', text: unique_id, category_ids: [cate1.id],
          member_group_ids: [group.id], group_ids: [group.id]
        )
      end
    end
    let!(:comment) do
      Timecop.freeze(now - 2.days) do
        Gws::Circular::Comment.create!(
          cur_site: site, cur_user: user, post: post, name: "Re: #{post.name}", text: unique_id,
          group_ids: [group.id]
        )
      end
    end

    it do
      # execute
      job = described_class.bind(site_id: site.id, task_id: task.id)
      expect { ss_perform_now(job, revision.name, job_opts) }.to output(include("[廃止] 成功: 1, 失敗: 0\n")).to_stdout

      expect(Gws::Group.where(id: group.id).first.active?).to be_falsey

      # confirm that relations was not changed with delete.
      Gws::Circular::Post.find(post.id).tap do |post_after_chorg|
        expect(post_after_chorg.member_group_ids).to eq post.group_ids
        expect(post_after_chorg.group_ids).to eq post.group_ids
        expect(post_after_chorg.updated).to eq post.updated
        expect(post_after_chorg.created).to eq post.created
      end

      Gws::Circular::Comment.find(comment.id).tap do |comment_after_chorg|
        expect(comment_after_chorg.group_ids).to eq comment.group_ids
        expect(comment_after_chorg.updated).to eq comment.updated
        expect(comment_after_chorg.created).to eq comment.created
      end

      Gws::Circular::Category.find(cate1.id).tap do |cate_after_chorg|
        expect(cate_after_chorg.group_ids).to eq cate1.group_ids
      end
    end
  end
end
