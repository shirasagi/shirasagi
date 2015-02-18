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
  end

  describe "#find_by_domain" do
    context "when domain can find" do
      subject {
        host = model.last.domains[0]
        model.find_by_domain host
      }

      it { expect(subject.domain).not_to eq nil }
      it { expect(subject.path).not_to eq nil }
      it { expect(subject.url).not_to eq nil }
      it { expect(subject.full_url).not_to eq nil }
    end

    context "when domain cannot find" do
      subject {
        host = SecureRandom.hex(20)
        model.find_by_domain host
      }

      it { expect(subject).to eq nil }
    end
  end

  describe "#root_group" do
    subject { ss_site }
    it { expect(subject.root_group).not_to be nil }
  end

  context "when multiple rooted site is given" do
    let(:group1) { create(:ss_group, name: unique_id) }
    let(:group2) { create(:ss_group, name: unique_id) }
    subject do
      create(:cms_site, name: unique_id, host: unique_id, domains: ["#{unique_id}.example.jp"],
             group_ids: [group1.id, group2.id])
    end

    after :all do
      group1.delete if group1.present?
      group2.delete if group2.present?
    end

    it { expect { subject.root_group }.to raise_error SS::Site::Model::MultipleRootGroupsError }
  end
end
