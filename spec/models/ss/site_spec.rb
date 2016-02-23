require 'spec_helper'

describe SS::Site do
  subject(:model) { SS::Site }

  describe "#save and #find" do
    subject(:factory) { :ss_site }
    it_behaves_like "mongoid#save"
    it_behaves_like "mongoid#find"
  end

  describe "#attributes" do
    subject { ss_site }
    it { expect(subject.domain).not_to eq nil }
    it { expect(subject.path).not_to eq nil }
    it { expect(subject.url).not_to eq nil }
    it { expect(subject.full_url).not_to eq nil }
    it { expect(subject.mobile_state).to eq 'enabled' }
    it { expect(subject.mobile_location).to eq '/mobile' }
    it { expect(subject.mobile_css).to eq ['%{assets_prefix}/cms/mobile.css'] }
    it { expect(subject.trans_sid).to eq 'none' }
    it { expect(subject.mobile_disabled?).to be_falsey }
    it { expect(subject.mobile_enabled?).to be_truthy }
  end

  describe "#find_by_domain" do
    context "when domain can find" do
      let(:site) { ss_site }
      subject { model.find_by_domain site.domains[0] }
      it { expect(subject.domain).not_to eq nil }
      it { expect(subject.path).not_to eq nil }
      it { expect(subject.url).not_to eq nil }
      it { expect(subject.full_url).not_to eq nil }
      it { expect(subject.mobile_state).to eq 'enabled' }
      it { expect(subject.mobile_location).to eq '/mobile' }
      it { expect(subject.mobile_css).to eq ['%{assets_prefix}/cms/mobile.css'] }
      it { expect(subject.trans_sid).to eq 'none' }
      it { expect(subject.mobile_disabled?).to be_falsey }
      it { expect(subject.mobile_enabled?).to be_truthy }
    end

    context "when domain cannot find" do
      subject { model.find_by_domain "host-#{unique_id}" }
      it { expect(subject).to eq nil }
    end
  end

  describe "#root_group" do
    subject { create(:ss_site, host: "#{unique_id}", domains: ["#{unique_id}.com"], group_ids: [ss_group.id]) }
    it { expect(subject.root_group).not_to be_nil }
  end
end
