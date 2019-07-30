require 'spec_helper'

describe Gws::Attendance::DownloadParam, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  subject! { described_class.new(cur_site: site, cur_user: user) }

  describe "#from_date" do
    it do
      subject.from_date = nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:from_date]).to have(1).items
    end

    it do
      subject.from_date = "aaaa"
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:from_date]).to have(1).items
    end
  end

  describe "#to_date" do
    it do
      subject.to_date = nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:to_date]).to have(1).items
    end

    it do
      subject.to_date = "aaaa"
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:to_date]).to have(1).items
    end

    it do
      subject.from_date = "2019/07/02"
      subject.to_date = "2019/07/01"
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:to_date]).to have(1).items
    end

    it do
      subject.from_date = "2019/07/01"
      subject.to_date = "2019/07/01"
      subject.validate
      expect(subject.errors[:to_date]).to have(0).items
    end
  end

  describe "#user_ids" do
    it do
      subject.user_ids = nil
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:user_ids]).to have(1).items
    end

    it do
      subject.user_ids = %w(abc)
      expect(subject.valid?).to be_falsey
      expect(subject.errors[:user_ids]).to have(1).items
    end
  end
end
