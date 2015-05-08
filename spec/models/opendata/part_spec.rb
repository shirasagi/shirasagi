require 'spec_helper'

describe Opendata::Part::MypageLogin, dbscope: :example do
  subject { create(:opendata_part_mypage_login) }
  it { is_expected.not_to be_nil }
end

describe Opendata::Part::Dataset, dbscope: :example do
  subject { create(:opendata_part_dataset) }

  describe "#condition_hash" do
    its(:condition_hash) { is_expected.to be_empty }
  end

  describe "#sort_options" do
    it { expect(subject.sort_options).to include(%w(新着順 released), %w(人気順 popular), %w(注目順 attention)) }
  end

  describe "#sort_hash" do
    it do
      subject.sort = "released"
      expect(subject.sort_hash).to include(released: -1, _id: -1)
    end
    it do
      subject.sort = "popular"
      expect(subject.sort_hash).to include(point: -1, _id: -1)
    end
    it do
      subject.sort = "attention"
      expect(subject.sort_hash).to include(downloaded: -1, _id: -1)
    end
    it do
      subject.sort = nil
      expect(subject.sort_hash).to include(released: -1)
    end
  end

  describe "#template_variable_get" do
    it { expect(subject.template_variable_get(OpenStruct.new(point: "5"), "point")).to eq 5 }
    it { expect(subject.template_variable_get(OpenStruct.new(point: "5"), "xxxx")).to be_falsey }
  end
end

describe Opendata::Part::DatasetGroup, dbscope: :example do
  subject { create(:opendata_part_dataset_group) }

  describe "#condition_hash" do
    its(:condition_hash) { is_expected.to be_empty }
  end
end

describe Opendata::Part::App, dbscope: :example do
  subject { create(:opendata_part_app) }

  describe "#condition_hash" do
    its(:condition_hash) { is_expected.to be_empty }
  end

  describe "#sort_options" do
    it { expect(subject.sort_options).to include(%w(新着順 released), %w(人気順 popular), %w(注目順 attention)) }
  end

  describe "#sort_hash" do
    it do
      subject.sort = "released"
      expect(subject.sort_hash).to include(released: -1, _id: -1)
    end
    it do
      subject.sort = "popular"
      expect(subject.sort_hash).to include(point: -1, _id: -1)
    end
    it do
      subject.sort = "attention"
      expect(subject.sort_hash).to include(executed: -1, _id: -1)
    end
    it do
      subject.sort = nil
      expect(subject.sort_hash).to include(released: -1)
    end
  end

  describe "#template_variable_get" do
    it { expect(subject.template_variable_get(OpenStruct.new(point: "5"), "point")).to eq 5 }
    it { expect(subject.template_variable_get(OpenStruct.new(point: "5"), "xxxx")).to be_falsey }
  end
end

describe Opendata::Part::Idea, dbscope: :example do
  subject { create(:opendata_part_idea) }

  describe "#condition_hash" do
    its(:condition_hash) { is_expected.to be_empty }
  end

  describe "#sort_options" do
    it { expect(subject.sort_options).to include(%w(新着順 released), %w(人気順 popular), %w(注目順 attention)) }
  end

  describe "#sort_hash" do
    it do
      subject.sort = "released"
      expect(subject.sort_hash).to include(released: -1, _id: -1)
    end
    it do
      subject.sort = "popular"
      expect(subject.sort_hash).to include(point: -1, _id: -1)
    end
    it do
      subject.sort = "attention"
      expect(subject.sort_hash).to include(commented: -1, _id: -1)
    end
    it do
      subject.sort = nil
      expect(subject.sort_hash).to include(released: -1)
    end
  end

  describe "#sort_criteria" do
    context "when sort is released" do
      let(:criteria) do
        subject.sort = "released"
        subject.sort_criteria
      end
      it { expect(criteria.selector.to_h).to include("route" => "opendata/idea") }
      it { expect(criteria.options.to_h).to include(sort: include("released" => -1, "_id" => -1)) }
    end
    context "when sort is popular" do
      let(:criteria) do
        subject.sort = "popular"
        subject.sort_criteria
      end
      it { expect(criteria.selector.to_h).to include("route" => "opendata/idea") }
      it { expect(criteria.options.to_h).to include(sort: include("point" => -1, "_id" => -1)) }
    end
    context "when sort is attention" do
      let(:criteria) do
        subject.sort = "attention"
        subject.sort_criteria
      end
      it { expect(criteria.selector.to_h).to include("route" => "opendata/idea", "commented" => include("$ne" => nil)) }
      it { expect(criteria.options.to_h).to include(sort: include("commented" => -1, "_id" => -1)) }
    end
    context "when sort is nil" do
      let(:criteria) do
        subject.sort = nil
        subject.sort_criteria
      end
      it { expect(criteria.selector.to_h).to include("route" => "opendata/idea") }
      it { expect(criteria.options.to_h).to include(sort: include("released" => -1)) }
    end
  end

  describe "#template_variable_get" do
    it { expect(subject.template_variable_get(OpenStruct.new(point: "5"), "point")).to eq 5 }
    it { expect(subject.template_variable_get(OpenStruct.new(point: "5"), "xxxx")).to be_falsey }
  end
end
