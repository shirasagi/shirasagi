require 'spec_helper'

describe Cms::Elasticsearch::Searcher, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:setting) { Cms::Elasticsearch::Setting::Page.new(cur_site: site, cur_user: user) }
  let(:item) { described_class.new(setting: setting) }

  describe 'methods' do
    it do
      expect(item.type).to eq [:cms_pages]
    end
  end
end
