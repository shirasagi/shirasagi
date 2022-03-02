require 'spec_helper'

describe Jmaxml::QuakeRegion, dbscope: :example do
  let(:site) { cms_site }

  describe 'basic attributes' do
    subject { create(:jmaxml_region_c110) }
    its(:site_id) { is_expected.to eq site.id }
    its(:name) { is_expected.to eq '檜山支庁' }
    its(:code) { is_expected.to eq '110' }
    its(:order) { is_expected.to eq 110 }
  end
end
