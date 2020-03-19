require 'spec_helper'

RSpec.describe Gws::Circular::Post, type: :model, dbscope: :example do
  let(:model) { described_class }

  describe "topic" do
    context "blank params" do
      subject { Gws::Circular::Post.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    context "default params" do
      subject { create(:gws_circular_post, :member_ids, :due_date) }
      it { expect(subject.errors.size).to eq 0 }
    end

    context "when member_ids are missing" do
      subject { build(:gws_circular_post, :due_date).valid? }
      it { expect(subject).to be_falsey }
    end

    context "when due_date is missing" do
      subject { build(:gws_circular_post, :member_ids).valid? }
      it { expect(subject).to be_falsey }
    end
  end

  describe "#to_csv" do
    subject { create(:gws_circular_post, :member_ids, :due_date) }
    it { expect(Gws::Circular::Post.to_csv).to be_truthy }
  end

  describe "#send_notification" do
    let(:site) { gws_site }
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user1) { create :gws_user, group_ids: [group1.id] }
    let!(:user2) { create :gws_user, group_ids: [group2.id] }
    let!(:user3) { create :gws_user, group_ids: [group3.id] }
    let!(:user4) { create :gws_user, group_ids: [group2.id], account_expiration_date: 1.day.ago }
    let!(:cg_by_user) { create :gws_custom_group, member_ids: [user1.id, user2.id] }
    let!(:cg_by_group) { create :gws_custom_group, member_group_ids: [group1.id, group2.id] }
    let!(:item) { create :gws_circular_post, init.merge(due_date: 1.day.from_now, state: "draft") }

    context 'member_ids are set' do
      let(:init) do
        { member_ids: [user1.id, user3.id, user4.id], member_group_ids: [], member_custom_group_ids: [] }
      end

      it do
        expect(SS::Notification.all.count).to eq 0

        # publish circular
        item.state = "public"
        item.save!

        expect(SS::Notification.all.count).to eq 1
        SS::Notification.first.tap do |notice|
          expect(notice.group_id).to eq site.id
          expect(notice.member_ids.length).to eq 2
          expect(notice.member_ids).to include(user1.id, user3.id)
          expect(notice.user_id).to eq item.user.id
          expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post.subject", name: item.name)
          expect(notice.text).to be_blank
          expect(notice.html).to be_blank
          expect(notice.format).to eq "text"
          expect(notice.seen).to be_blank
          expect(notice.state).to eq "public"
          expect(notice.send_date).to be_present
          expect(notice.url).to eq "/.g#{site.id}/circular/-/posts/#{item.id}"
          expect(notice.reply_module).to be_blank
          expect(notice.reply_model).to be_blank
          expect(notice.reply_item_id).to be_blank
        end

        # clean up notifications
        SS::Notification.all.destroy_all

        # modify item
        item.name = "name-#{unique_id}"
        item.text = "text-#{unique_id}"
        item.save!

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context 'member_group_ids are set' do
      let(:init) do
        { member_ids: [], member_group_ids: [group2.id, group3.id], member_custom_group_ids: [] }
      end

      it do
        expect(SS::Notification.all.count).to eq 0

        # publish circular
        item.state = "public"
        item.save!

        expect(SS::Notification.all.count).to eq 1
        SS::Notification.first.tap do |notice|
          expect(notice.group_id).to eq site.id
          expect(notice.member_ids.length).to eq 2
          expect(notice.member_ids).to include(user2.id, user3.id)
          expect(notice.user_id).to eq item.user.id
          expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post.subject", name: item.name)
          expect(notice.text).to be_blank
          expect(notice.html).to be_blank
          expect(notice.format).to eq "text"
          expect(notice.seen).to be_blank
          expect(notice.state).to eq "public"
          expect(notice.send_date).to be_present
          expect(notice.url).to eq "/.g#{site.id}/circular/-/posts/#{item.id}"
          expect(notice.reply_module).to be_blank
          expect(notice.reply_model).to be_blank
          expect(notice.reply_item_id).to be_blank
        end

        # clean up notifications
        SS::Notification.all.destroy_all

        # modify item
        item.name = "name-#{unique_id}"
        item.text = "text-#{unique_id}"
        item.save!

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context 'member_custom_groups contain users are set' do
      let(:init) do
        { member_ids: [], member_group_ids: [], member_custom_group_ids: [cg_by_user.id] }
      end

      it do
        expect(SS::Notification.all.count).to eq 0

        # publish circular
        item.state = "public"
        item.save!

        expect(SS::Notification.all.count).to eq 1
        SS::Notification.first.tap do |notice|
          expect(notice.group_id).to eq site.id
          expect(notice.member_ids.length).to eq 2
          expect(notice.member_ids).to include(user1.id, user2.id)
          expect(notice.user_id).to eq item.user.id
          expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post.subject", name: item.name)
          expect(notice.text).to be_blank
          expect(notice.html).to be_blank
          expect(notice.format).to eq "text"
          expect(notice.seen).to be_blank
          expect(notice.state).to eq "public"
          expect(notice.send_date).to be_present
          expect(notice.url).to eq "/.g#{site.id}/circular/-/posts/#{item.id}"
          expect(notice.reply_module).to be_blank
          expect(notice.reply_model).to be_blank
          expect(notice.reply_item_id).to be_blank
        end

        # clean up notifications
        SS::Notification.all.destroy_all

        # modify item
        item.name = "name-#{unique_id}"
        item.text = "text-#{unique_id}"
        item.save!

        expect(SS::Notification.all.count).to eq 0
      end
    end

    context 'member_custom_groups contain groups are set' do
      let(:init) do
        { member_ids: [], member_group_ids: [], member_custom_group_ids: [cg_by_group.id] }
      end

      it do
        expect(SS::Notification.all.count).to eq 0

        # publish circular
        item.state = "public"
        item.save!

        expect(SS::Notification.all.count).to eq 1
        SS::Notification.first.tap do |notice|
          expect(notice.group_id).to eq site.id
          expect(notice.member_ids.length).to eq 2
          expect(notice.member_ids).to include(user1.id, user2.id)
          expect(notice.user_id).to eq item.user.id
          expect(notice.subject).to eq I18n.t("gws_notification.gws/circular/post.subject", name: item.name)
          expect(notice.text).to be_blank
          expect(notice.html).to be_blank
          expect(notice.format).to eq "text"
          expect(notice.seen).to be_blank
          expect(notice.state).to eq "public"
          expect(notice.send_date).to be_present
          expect(notice.url).to eq "/.g#{site.id}/circular/-/posts/#{item.id}"
          expect(notice.reply_module).to be_blank
          expect(notice.reply_model).to be_blank
          expect(notice.reply_item_id).to be_blank
        end

        # clean up notifications
        SS::Notification.all.destroy_all

        # modify item
        item.name = "name-#{unique_id}"
        item.text = "text-#{unique_id}"
        item.save!

        expect(SS::Notification.all.count).to eq 0
      end
    end
  end
end
