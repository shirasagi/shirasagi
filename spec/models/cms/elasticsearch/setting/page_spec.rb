require 'spec_helper'

describe Cms::Elasticsearch::Setting::Page, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:item) { described_class.new(cur_site: site, cur_user: user) }

  describe 'methods' do
    it do
      expect(item.search_settings.blank?).to be_truthy
      expect(item.search_types).to eq [:cms_pages]
    end
  end
end
