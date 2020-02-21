require 'spec_helper'

describe Gws::Elasticsearch::Setting::All, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:item) { described_class.new(cur_site: site, cur_user: user) }
  let!(:custom_group) { create :gws_custom_group }

  describe 'methods' do
    it do
      expect(item.allowed?(:method)).to be_falsey
      expect(item.manageable_filter.blank?).to be_truthy
      expect(item.translate_type('unknown')).to eq 'unknown'
      expect(item.type).to eq 'all'
    end
  end
end
