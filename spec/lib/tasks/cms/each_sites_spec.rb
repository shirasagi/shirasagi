require 'spec_helper'

describe Tasks::Cms, dbscope: :example do
  describe ".each_sites" do
    let!(:site1) { create :cms_site_unique }
    let!(:site2) { create :cms_site_unique }
    let!(:site3) { create :cms_site_unique }

    before do
      @save = {}
      ENV.each do |key, value|
        @save[key.dup] = value.dup
      end
    end

    after do
      ENV.clear
      @save.each do |key, value|
        ENV[key] = value
      end
    end

    context "without params" do
      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        expect(site_ids.length).to eq 3
        expect(site_ids).to include(site1.id, site2.id, site3.id)
      end
    end

    context "with site" do
      before { ENV['site'] = site1.host }

      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        expect(site_ids.length).to eq 1
        expect(site_ids).to include(site1.id)
      end
    end

    context "with include_sites" do
      before { ENV['include_sites'] = site1.host }

      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        expect(site_ids.length).to eq 1
        expect(site_ids).to include(site1.id)
      end
    end

    context "with include_sites with multiple sites" do
      before { ENV['include_sites'] = [ site1.host, site2.host ].join(",,,、、、") }

      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        expect(site_ids.length).to eq 2
        expect(site_ids).to include(site1.id, site2.id)
      end
    end

    context "with exclude_sites" do
      before { ENV['exclude_sites'] = site1.host }

      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        expect(site_ids.length).to eq 2
        expect(site_ids).to include(site2.id, site3.id)
      end
    end

    context "with exclude_sites with multiple sites" do
      before { ENV['exclude_sites'] = [ site1.host, site2.host ].join(",,,、、、") }

      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        expect(site_ids.length).to eq 1
        expect(site_ids).to include(site3.id)
      end
    end

    context "with site and include_sites" do
      before do
        ENV['site'] = site1.host
        ENV['include_sites'] = site2.host
      end

      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        # only 'site' is effective
        expect(site_ids.length).to eq 1
        expect(site_ids).to include(site1.id)
      end
    end

    context "with include_sites and exclude_sites" do
      before do
        ENV['include_sites'] = [ site1.host, site2.host ].join(",,,、、、")
        ENV['exclude_sites'] = site2.host
      end

      it do
        site_ids = []
        described_class.each_sites do |site|
          site_ids << site.id
        end

        # first include_sites is applied, and then exclude_sites is applied
        expect(site_ids.length).to eq 1
        expect(site_ids).to include(site1.id)
      end
    end
  end
end
