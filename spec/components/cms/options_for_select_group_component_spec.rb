require 'spec_helper'

describe Cms::OptionsForSelectGroupComponent, type: :component, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:user0) { cms_user }
  let!(:group) { create :cms_group, name: unique_id }
  let!(:site) { create :cms_site_unique, group_ids: [ group.id ] }
  let!(:role) { create :cms_role_admin, cur_site: site, site: site }
  let!(:user) { create :cms_test_user, group_ids: [ group.id ], cms_role_ids: [ role.id ] }
  let!(:component) { described_class.new(cur_site: site) }
  let(:nbsp) { "\u00A0" }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true

    create(:cms_group, name: "#{group.name}/BBB")
    create(:cms_group, name: "#{group.name}/CCC", order: 30)
    create(:cms_group, name: "#{group.name}/BBB/DDDD", order: 40)
    create(:cms_group, name: "#{group.name}/BBB/EEEE", order: 70)
    create(:cms_group, name: "#{group.name}/CCC/FFFF", order: 50)
    create(:cms_group, name: "#{group.name}/CCC/GGGG", order: 60)
    # lost child
    create(:cms_group, name: "#{group.name}/HHH/IIII", order: 0)
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  it do
    expect(component.cache_exist?).to be_falsey

    html = render_inline component
    html.css("option").tap do |nodes|
      expect(nodes).to have(8).items
      expect(nodes[0].text).to eq group.name
      expect(nodes[1].text).to eq "+----BBB"
      expect(nodes[2].text).to eq "#{nbsp * 8}+----DDDD"
      expect(nodes[3].text).to eq "#{nbsp * 8}+----EEEE"
      expect(nodes[4].text).to eq "+----CCC"
      expect(nodes[5].text).to eq "#{nbsp * 8}+----FFFF"
      expect(nodes[6].text).to eq "#{nbsp * 8}+----GGGG"
      expect(nodes[7].text).to eq "+----HHH/IIII"
    end

    expect(component.cache_exist?).to be_truthy

    html = render_inline described_class.new(cur_site: site)
    html.css("option").tap do |nodes|
      expect(nodes).to have(8).items
      expect(nodes[0].text).to eq group.name
      expect(nodes[1].text).to eq "+----BBB"
      expect(nodes[2].text).to eq "#{nbsp * 8}+----DDDD"
      expect(nodes[3].text).to eq "#{nbsp * 8}+----EEEE"
      expect(nodes[4].text).to eq "+----CCC"
      expect(nodes[5].text).to eq "#{nbsp * 8}+----FFFF"
      expect(nodes[6].text).to eq "#{nbsp * 8}+----GGGG"
      expect(nodes[7].text).to eq "+----HHH/IIII"
    end
  end
end
