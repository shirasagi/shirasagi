require 'spec_helper'

describe Gws::Portal::UserPortlet, type: :model, dbscope: :example do
  let!(:portal) { create :gws_portal_user_setting, cur_user: gws_user, cur_group: gws_user.groups.first }
  let!(:portlet) { create :gws_portal_user_portlet, :gws_portal_notice_portlet, cur_user: gws_user, setting: portal, limit: 100 }
  let!(:folder0) { create :gws_notice_folder, readable_setting_range: 'public' }
  let!(:folder1) { create :gws_notice_folder, readable_setting_range: 'public' }
  let!(:folder2) { create :gws_notice_folder, readable_setting_range: 'public' }
  let!(:category1) { create :gws_notice_category, readable_setting_range: 'public' }
  let!(:category2) { create :gws_notice_category, readable_setting_range: 'public' }
  let!(:post1) do
    create(
      :gws_notice_post, folder: folder1,
      readable_setting_range: 'public', state: 'public'
    )
  end
  let!(:post2) do
    create(
      :gws_notice_post, folder: folder2, severity: 'high',
      readable_setting_range: 'public', state: 'public'
    )
  end
  let!(:post3) do
    create(
      :gws_notice_post, folder: folder0, category_ids: [ category1.id ],
      readable_setting_range: 'public', state: 'public'
    )
  end
  let!(:post4) do
    create(
      :gws_notice_post, folder: folder0, severity: 'high', category_ids: [ category2.id ],
      readable_setting_range: 'public', state: 'public'
    )
  end
  let!(:post5) do
    create(
      :gws_notice_post, folder: folder0, category_ids: [ category1.id, category2.id ],
      readable_setting_range: 'public', state: 'public'
    )
  end
  let!(:post_closed) do
    create(:gws_notice_post, folder: folder0, readable_setting_range: 'public', state: 'closed')
  end
  let!(:post_deleted) do
    create(:gws_notice_post, folder: folder0, readable_setting_range: 'public', deleted: Time.zone.now)
  end
  let!(:post_unreadable) do
    user = create(:gws_user, group_ids: gws_user.group_ids)
    create(
      :gws_notice_post, folder: folder1, readable_setting_range: 'select',
      readable_group_ids: [], readable_member_ids: [ user.id ], readable_custom_group_ids: []
    )
  end

  describe "#find_notice_items" do
    subject { portlet.find_notice_items(portal, gws_user).pluck(:id) }

    context "without any options" do
      it do
        expect(subject.length).to eq 5
      end
    end

    context "with notice_severity" do
      context "with 'high'" do
        before do
          portlet.notice_severity = "high"
          portlet.save!
        end

        it do
          expect(subject.length).to eq 2
        end
      end
    end

    context "with notice_browsed_state" do
      before do
        post1.set_browsed!(gws_user)
        post3.set_browsed!(gws_user)
        post5.set_browsed!(gws_user)
      end

      context "with default (site's unread)" do
        it do
          expect(subject.length).to eq 2
        end
      end

      context "with both" do
        before do
          portlet.notice_browsed_state = "both"
          portlet.save!
        end

        it do
          expect(subject.length).to eq 5
        end
      end

      context "with 'unread'" do
        before do
          portlet.notice_browsed_state = "unread"
          portlet.save!
        end

        it do
          expect(subject.length).to eq 2
        end
      end

      context "with 'read'" do
        before do
          portlet.notice_browsed_state = "read"
          portlet.save!
        end

        it do
          expect(subject.length).to eq 3
        end
      end
    end

    context "with notice_category_ids" do
      before do
        portlet.notice_category_ids = [ category1.id ]
        portlet.save!
      end

      it do
        expect(subject.length).to eq 2
      end
    end

    context "with notice_folder_ids" do
      before do
        portlet.notice_folder_ids = [ folder1.id ]
        portlet.save!
      end

      it do
        expect(subject.length).to eq 1
      end
    end
  end
end
