require 'spec_helper'

describe Gws, type: :model, dbscope: :example do
  let!(:site) { create :gws_group, name: unique_id }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:user) { create :gws_user, group_ids: [ group2.id ] }
  let!(:other_site) { create :gws_group, name: unique_id }
  let(:png_file) do
    filename = "#{Rails.root}/spec/fixtures/ss/logo.png"
    basename = File.basename(filename)
    SS::File.create_empty!(
      site_id: site.id, cur_user: cms_user, name: basename, filename: basename, content_type: "image/png", model: 'ss/file'
    ) do |file|
      FileUtils.cp(filename, file.path)
    end
  end

  it { expect(Gws.find_gws_quota_used(Gws::Group.where(id: site.id))).to be >= 1_500 }

  context "when gws/attendance/time_card is created" do
    it do
      expect { create(:gws_attendance_time_card, :with_records, cur_site: site, cur_user: user) }.to \
        change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(5_000)
    end
  end

  context "when gws/board/topic is created" do
    it do
      expect { create(:gws_board_topic, cur_site: site, cur_user: user) }.to \
        change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(900)
    end
  end

  context "when gws/bookmark is created" do
    it do
      expect { create(:gws_bookmark_item, cur_site: site, cur_user: user) }.to \
        change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(200)
    end
  end

  context "when gws/chorg/revision is created" do
    it do
      expectation = expect do
        revision = create(:gws_revision, cur_site: site)
        create(:gws_add_changeset, revision_id: revision.id)
        create(:gws_move_changeset, revision_id: revision.id, source: group2)
        create(:gws_unify_changeset, revision_id: revision.id, sources: [group1, group2])
        create(:gws_division_changeset, revision_id: revision.id, source: group1, destinations: [group2])
        create(:gws_delete_changeset, revision_id: revision.id, source: group1)
      end
      expectation.to change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(100)
    end
  end

  context "when gws/circular/post is created" do
    it do
      expect { create(:gws_circular_post, cur_site: site, cur_user: user, due_date: Time.zone.now, member_ids: [ user.id ]) }.to \
        change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(500)
    end
  end

  context "when gws/contrast is created" do
    it do
      expect { create(:gws_contrast, cur_site: site) }.to \
        change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(100)
    end
  end

  context "when gws/custom_group is created" do
    it do
      expect { create(:gws_custom_group, cur_site: site, cur_user: user, member_ids: [ user.id ]) }.to \
        change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(500)
    end
  end

  context "when gws/discussion/topic is created" do
    it do
      expectation = expect do
        forum = create(:gws_discussion_forum, cur_site: site, cur_user: user)
        create(:gws_discussion_topic, cur_site: site, cur_user: user, forum: forum)
      end
      expectation.to change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(1_500)
    end
  end

  context "when gws/group is created" do
    context "when child group is created" do
      it do
        expect { create(:gws_group, name: "#{group1.name}/#{unique_id}") }.to \
          change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(2_000)
      end
    end

    context "when other organization group is created" do
      it do
        expect { create(:gws_group, name: unique_id) }.to \
          change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by(0)
      end
    end

    context "when none-active group is created" do
      it do
        expect { create(:gws_group, name: "#{group1.name}/#{unique_id}", expiration_date: Time.zone.now - 1.minute) }.to \
          change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(2_000)
      end
    end
  end

  context "when gws/user is created" do
    context "with usual case" do
      it do
        expect { create(:gws_user, uid: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group1.id ]) }.to \
          change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(1_500)
      end
    end

    context "when other organization user is created" do
      it do
        expectation = expect do
          create(:gws_user, uid: unique_id, email: "#{unique_id}@example.jp", group_ids: [ other_site.id ])
        end
        expectation.to change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by(0)
      end
    end

    context "when none-active user is created" do
      it do
        expectation = expect do
          time = Time.zone.now - 1.minute
          create(
            :gws_user, uid: unique_id, email: "#{unique_id}@example.jp", account_expiration_date: time, group_ids: [ group1.id ]
          )
        end
        expectation.to change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(1_500)
      end
    end
  end

  context "when gws/role is created" do
    it do
      expect { create(:gws_role_admin, cur_site: site, name: unique_id) }.to \
        change { Gws.find_gws_quota_used(Gws::Group.where(id: site.id)) }.by_at_least(10_000)
    end
  end
end
