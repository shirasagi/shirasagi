require 'spec_helper'

describe Job::BindedJob, dbscope: :example do
  let(:site) { create(:ss_site) }
  let(:job_class) { SS::ExampleJob }

  describe "#set" do
    subject { described_class.new(job_class).set(wait: 1.week) }
    it { expect(subject.options[:wait]).to eq 1.week }
  end

  describe "#bind" do
    context "with symbol key" do
      subject { described_class.new(job_class).bind(site_id: site) }
      it { expect(subject.bindings["site_id"]).to be site }
    end

    context "with string key" do
      subject { described_class.new(job_class).bind("site_id" => site) }
      it { expect(subject.bindings["site_id"]).to be site }
    end
  end

  context "set and bind" do
    subject { described_class.new(job_class).set(wait: 1.week).bind(site_id: site) }
    it { expect(subject.options[:wait]).to eq 1.week }
    it { expect(subject.bindings["site_id"]).to be site }
  end

  context "bind and set" do
    subject { described_class.new(job_class).bind(site_id: site).set(wait: 1.week) }
    it { expect(subject.options[:wait]).to eq 1.week }
    it { expect(subject.bindings["site_id"]).to be site }
  end

  describe "#perform_now" do
    subject { described_class.new(job_class).bind(site_id: site) }
    it { expect(subject.perform_now("hellow")).not_to be_nil }
  end

  describe "#perform_later" do
    subject { described_class.new(job_class).set(wait: 3.minutes).bind(site_id: site) }
    it do
      expect(subject.perform_later("hellow")).to be_a(job_class)
      expect(enqueued_jobs.size).to eq 1
    end
  end
end
