require 'spec_helper'

RSpec.describe Gws::Monitor::Topic, type: :model, dbscope: :example, tmpdir: true do
  let(:model) { described_class }

  describe "topic" do
    context "blank params" do
      subject { Gws::Monitor::Topic.new(cur_site: gws_site, cur_user: gws_user).valid? }
      it { expect(subject).to be_falsey }
    end

    # context "default params" do
    #   subject { create :gws_monitor_topic }
    #   it { expect(subject.errors.size).to eq 0 }
    # end

    context "default params" do
      subject { create :gws_monitor_topic }
      it 'subject no errors' do
        expect(subject.errors.size).to eq 0
      end
      it 'subject can save' do
        #p subject
        expect(subject.save).to be_truthy
      end
      it '1 + 1 = 2' do
        expect(1 + 1).to eq 2
      end
      it 'model can save' do
        #cur_user = Gws::User.new(_id: 1, group_ids: [10], name: "name-1", uid: "uid-1", email: "uid-q@example.jp", in_password: "pass")
        cur_group = Gws::Group.new(_id: 1, name: "シラサギ市".force_encoding("utf-8"))
        #topic = Gws::Monitor::Topic.new(user_uid: "admin", user_group_name: "gw-admin", user_id: 2, site_id: 1, name: "test", attend_group_ids: [10])
        #topic = Gws::Monitor::Topic.new(site_id: 1, name: "test", attend_group_ids: [10], cur_site: cur_group, cur_user: cur_user)
        #topic = Gws::Monitor::Topic.new(site_id: 1, name: "test", attend_group_ids: [10], cur_site: cur_group)
        topic = model.new(site_id: 1, name: "test", attend_group_ids: [10], cur_site: cur_group)
        topic.site = cur_group
        expect(topic.save).to be_truthy
      end
    end

    # context "default params" do
    #   subject { create :gws_monitor_topic }
    #   it { expect(model.new.save).to be_truthy }
    #
    #   #topic = Gws::Monitor::Topic.new(name: "テスト記事", attend_group_ids: [10])
    #   #expect(topic.save).to be_true
    # end
  end

  describe "#closed?" do
    it 'true' do
      topic = Gws::Monitor::Topic.new(name: "test", attend_group_ids: [10], article_state: "closed")
      expect(topic.closed?).to be_truthy
    end

    it 'false' do
      topic = Gws::Monitor::Topic.new(name: "test", attend_group_ids: [10], article_state: "open")
      expect(topic.closed?).to be_falsey
    end
  end
end
