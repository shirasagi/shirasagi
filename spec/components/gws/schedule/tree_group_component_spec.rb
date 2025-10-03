require 'spec_helper'

describe Gws::Schedule::TreeGroupComponent, type: :component, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:component) { described_class.new(cur_site: site, cur_user: user) }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  it do
    expect(component.cache_exist?).to be_falsey

    html = render_inline component
    html.css("[data-node-id='#{site.id}']").tap do |element|
      expect(element).to have(1).items
      expect(element.to_html).to include(site.name)
    end
    site.descendants_and_self.each do |group|
      html.css("[data-node-id='#{group.id}']").tap do |element|
        expect(element).to have(1).items
        expect(element.to_html).to include(group.trailing_name)
      end
    end

    expect(component.cache_exist?).to be_truthy

    html = render_inline described_class.new(cur_site: site, cur_user: user)
    html.css("[data-node-id='#{site.id}']").tap do |element|
      expect(element).to have(1).items
      expect(element.to_html).to include(site.name)
    end
    site.descendants_and_self.each do |group|
      html.css("[data-node-id='#{group.id}']").tap do |element|
        expect(element).to have(1).items
        expect(element.to_html).to include(group.trailing_name)
      end
    end
  end
end
