require 'spec_helper'

describe Cms::Apis::GroupsComponent, type: :component, dbscope: :example do
  let!(:site0) { cms_site }
  let!(:user0) { cms_user }
  let!(:root_group) { create :cms_group, name: unique_id }
  let!(:site) { create :cms_site_unique, group_ids: [ root_group.id ] }
  let!(:component) { described_class.new(cur_site: site, multi: true) }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true

    create(:cms_group, name: "#{root_group.name}/BBB")
    create(:cms_group, name: "#{root_group.name}/CCC", order: 30)
    create(:cms_group, name: "#{root_group.name}/BBB/DDDD", order: 40)
    create(:cms_group, name: "#{root_group.name}/BBB/EEEE", order: 70)
    create(:cms_group, name: "#{root_group.name}/CCC/FFFF", order: 50)
    create(:cms_group, name: "#{root_group.name}/CCC/GGGG", order: 60)
    # lost child
    create(:cms_group, name: "#{root_group.name}/HHH/IIII", order: 0)
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  it do
    expect(component.cache_exist?).to be_falsey

    html = render_inline component
    html.css("tr[data-id='#{root_group.id}']").tap do |tr|
      expect(tr).to have(1).items
      expect(tr.to_html).to include(root_group.name)
    end
    root_group.descendants_and_self.each do |group|
      html.css("tr[data-id='#{group.id}']").tap do |tr|
        expect(tr).to have(1).items
        expect(tr.to_html).to include(group.trailing_name)
      end
    end

    expect(component.cache_exist?).to be_truthy

    html = render_inline described_class.new(cur_site: site, multi: true)
    html.css("tr[data-id='#{root_group.id}']").tap do |tr|
      expect(tr).to have(1).items
      expect(tr.to_html).to include(root_group.name)
    end
    root_group.descendants_and_self.each do |group|
      html.css("tr[data-id='#{group.id}']").tap do |tr|
        expect(tr).to have(1).items
        expect(tr.to_html).to include(group.trailing_name)
      end
    end

    expect(component.cache_exist?).to be_truthy

    html = render_inline described_class.new(cur_site: site, multi: false)
    html.css("tr[data-id='#{root_group.id}']").tap do |tr|
      expect(tr).to have(1).items
      expect(tr.to_html).to include(root_group.name)
    end
    root_group.descendants_and_self.each do |group|
      html.css("tr[data-id='#{group.id}']").tap do |tr|
        expect(tr).to have(1).items
        expect(tr.to_html).to include(group.trailing_name)
      end
    end
  end
end
