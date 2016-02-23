require 'spec_helper'

describe Cms::Notice, dbscope: :example do
  context "with defaults" do
    subject { described_class.create!(name: unique_id, cur_site: cms_site) }
    its(:name) { is_expected.not_to be_nil }
    its(:notice_severity) { is_expected.to eq described_class::NOTICE_SEVERITY_NORMAL }
    its(:notice_target) { is_expected.to eq described_class::NOTICE_TARGET_ALL }
  end

  describe ".search" do
    context "when nil is given" do
      subject { described_class.search(nil) }
      it { expect(subject.selector.to_h).to be_empty }
    end

    context "when name is given" do
      subject { described_class.search(name: "名前 なまえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名前/i, /なまえ/i))) }
    end

    context "when name includes regex meta characters" do
      subject { described_class.search(name: "名|前 な(*.?)まえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名\|前/i, /な\(\*\.\?\)まえ/i))) }
    end

    context "when keyword is given" do
      subject { described_class.search(keyword: "キーワード1 キーワード2") }
      it { expect(subject.selector.to_h).to include("$and" => include("$or" => include("name" => /キーワード1/i))) }
      it { expect(subject.selector.to_h).to include("$and" => include("$or" => include("name" => /キーワード2/i))) }
    end
  end

  describe ".public" do
    context "when no release_date/close_date is given" do
      subject { described_class.search(nil) }
      before { create(:cms_notice) }
      it { expect(subject.and_public.count).to eq 1 }
    end

    context "when release_date is given / no close_date is given" do
      subject { described_class.search(nil) }
      before { create(:cms_notice, release_date: 5.minutes.ago ) }
      it { expect(subject.and_public.count).to eq 1 }
      it { expect(subject.and_public(10.minutes.ago).count).to eq 0 }
    end

    context "when no release_date is given / close_date is given" do
      subject { described_class.search(nil) }
      before { create(:cms_notice, close_date: 5.minutes.from_now ) }
      it { expect(subject.and_public.count).to eq 1 }
      it { expect(subject.and_public(10.minutes.from_now).count).to eq 0 }
    end

    context "when release_date/close_date is given" do
      subject { described_class.search(nil) }
      before { create(:cms_notice, release_date: 5.minutes.ago, close_date: 5.minutes.from_now ) }
      it { expect(subject.and_public.count).to eq 1 }
      it { expect(subject.and_public(10.minutes.ago).count).to eq 0 }
      it { expect(subject.and_public(10.minutes.from_now).count).to eq 0 }
    end
  end

  describe ".target_to" do
    context "when notice_target is all" do
      let(:site) { cms_site }
      let(:root_group) { cms_group }
      let(:group1) { create(:cms_group, name: "#{root_group.name}/#{unique_id}") }
      let(:group2) { create(:cms_group, name: "#{root_group.name}/#{unique_id}") }
      let(:user1) { create(:cms_user, group: group1) }
      let(:user2) { create(:cms_user, group: group2) }
      before { create(:cms_notice, notice_target: described_class::NOTICE_TARGET_ALL, group_ids: [group1.id]) }
      it { expect(described_class.site(site).target_to(user1).count).to eq 1 }
      it { expect(described_class.site(site).target_to(user2).count).to eq 1 }
    end

    context "when notice_target is same_group" do
      let(:site) { cms_site }
      let(:root_group) { cms_group }
      let(:group1) { create(:cms_group, name: "#{root_group.name}/#{unique_id}") }
      let(:group2) { create(:cms_group, name: "#{root_group.name}/#{unique_id}") }
      let(:user0) { create(:cms_user, group: root_group) }
      let(:user1) { create(:cms_user, group: group1) }
      let(:user2) { create(:cms_user, group: group2) }

      context "when cms notice is registered in group1" do
        before do
          create(:cms_notice, notice_target: described_class::NOTICE_TARGET_SAME_GROUP, group_ids: [group1.id])
        end
        it { expect(described_class.site(site).target_to(user0).count).to eq 0 }
        it { expect(described_class.site(site).target_to(user1).count).to eq 1 }
        it { expect(described_class.site(site).target_to(user2).count).to eq 0 }
      end

      context "when cms notice is registered in root_group" do
        before do
          create(:cms_notice, notice_target: described_class::NOTICE_TARGET_SAME_GROUP, group_ids: [root_group.id])
        end
        it { expect(described_class.site(site).target_to(user0).count).to eq 1 }
        it { expect(described_class.site(site).target_to(user1).count).to eq 0 }
        it { expect(described_class.site(site).target_to(user2).count).to eq 0 }
      end

      context "when cms notice is registered in all groups" do
        before do
          create(:cms_notice, notice_target: described_class::NOTICE_TARGET_SAME_GROUP,
            group_ids: [root_group.id, group1.id, group2.id])
        end
        it { expect(described_class.site(site).target_to(user0).count).to eq 1 }
        it { expect(described_class.site(site).target_to(user1).count).to eq 1 }
        it { expect(described_class.site(site).target_to(user2).count).to eq 1 }
      end
    end
  end
end
