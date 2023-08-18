require 'spec_helper'

describe Gws::StaffRecord::YearlyGroupComponent, type: :component, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:now) { Time.zone.now.change(usec: 0) }
  let!(:year1) { create :gws_staff_record_year, cur_site: site, code: now.year - 1 }
  let!(:staff_record_group1) do
    create(
      :gws_staff_record_group, cur_site: site, year: year1, readable_setting_range: "public"
    )
  end
  let!(:year2) { create :gws_staff_record_year, cur_site: site, code: now.year - 2 }
  let!(:staff_record_group2) do
    create(
      :gws_staff_record_group, cur_site: site, year: year2, readable_setting_range: "public"
    )
  end

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  it do
    described_class.new(cur_site: site, cur_year: year1, selected: nil).tap do |component|
      expect(component.cache_exist?).to be_falsey

      html = render_inline component
      html.css("option[data-id='#{staff_record_group1.id}']").tap do |option|
        expect(option).to have(1).items
        expect(option.to_html).to include(staff_record_group1.name)
      end
      expect(component.cache_exist?).to be_truthy
    end

    described_class.new(cur_site: site, cur_year: year2, selected: nil).tap do |component|
      expect(component.cache_exist?).to be_falsey

      html = render_inline component
      html.css("option[data-id='#{staff_record_group2.id}']").tap do |option|
        expect(option).to have(1).items
        expect(option.to_html).to include(staff_record_group2.name)
      end
      expect(component.cache_exist?).to be_truthy
    end
  end
end
