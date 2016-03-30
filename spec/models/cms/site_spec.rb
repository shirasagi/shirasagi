require 'spec_helper'

describe Cms::Site do
  subject(:model) { Cms::Site }
  subject(:factory) { :ss_site }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"

  describe "#attributes" do
    subject(:item) { model.last }

    it { expect(item.domain).not_to eq nil }
    it { expect(item.path).not_to eq nil }
    it { expect(item.url).not_to eq nil }
    it { expect(item.full_url).not_to eq nil }
    it { expect(item.mobile_state).to eq 'enabled' }
    it { expect(item.mobile_location).to eq '/mobile' }
    it { expect(item.mobile_css).to eq ['%{assets_prefix}/cms/mobile.css'] }
    it { expect(item.mobile_disabled?).to be_falsey }
    it { expect(item.mobile_enabled?).to be_truthy }
  end

  context "when multiple rooted site is given" do
    let(:group1) { create(:cms_group, name: unique_id) }
    let(:group2) { create(:cms_group, name: unique_id) }
    subject do
      create(:cms_site, name: unique_id, host: unique_id,
             domains: ["#{unique_id}.example.jp"], group_ids: [group1.id, group2.id])
    end

    it { expect { subject.root_group }.to raise_error SS::Model::Site::MultipleRootGroupsError }
  end
end
