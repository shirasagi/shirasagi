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

  describe ".and_public" do
    context "when closed notice is given" do
      subject! { create(:cms_notice, state: "closed", release_date: nil, close_date: nil) }
      it { expect(described_class.and_public.count).to eq 0 }
    end

    context "when public notice without release plan is given" do
      subject! { create(:cms_notice, state: "public", release_date: nil, close_date: nil) }
      it { expect(described_class.and_public.first).to eq subject }
    end

    context "when public notice with release plan is given" do
      let(:current) { Time.zone.now.beginning_of_minute }
      let(:release_date) { current + 1.day }
      let(:close_date) { release_date + 1.day }
      subject! { create(:cms_notice, state: "public", release_date: release_date, close_date: close_date) }

      before do
        described_class.all.unset(:released)
        subject.reload
      end

      context "just before release date" do
        it do
          Timecop.freeze(release_date - 1.second) do
            expect(described_class.and_public.count).to eq 0
          end
        end
      end

      context "at release date" do
        it do
          Timecop.freeze(release_date) do
            expect(described_class.and_public.first).to eq subject
          end
        end
      end

      context "just before close date" do
        it do
          Timecop.freeze(close_date - 1.second) do
            expect(described_class.and_public.first).to eq subject
          end
        end
      end

      context "at close date" do
        it do
          Timecop.freeze(close_date) do
            expect(described_class.and_public.count).to eq 0
          end
        end
      end
    end
  end
end
