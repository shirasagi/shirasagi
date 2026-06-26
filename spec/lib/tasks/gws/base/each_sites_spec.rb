require 'spec_helper'

describe Tasks::Gws::Base, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site1) { create :gws_group, name: unique_id }
  let!(:site2) { create :gws_group, name: unique_id, expiration_date: now - 1.day }
  let!(:site3) { create :gws_group, name: unique_id, activation_date: now + 1.day }

  describe ".each_sites" do
    it do
      site_ids = []
      described_class.each_sites do |site|
        site_ids.append(site.id)
      end

      expect(site_ids).to have(1).items
      expect(site_ids).to include(site1.id)
      expect(site_ids).not_to include(site2.id)
      expect(site_ids).not_to include(site3.id)
    end
  end
end
