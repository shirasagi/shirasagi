require 'spec_helper'

describe SS, dbscope: :example do
  describe ".parse_threshold!" do
    let(:now) { Time.zone.now.change(usec: 0) }

    shared_examples "what parse_threshold! is" do
      it do
        default_duration = SS::Duration.parse("#{site.trash_threshold}.#{site.trash_threshold_unit}")
        expect(SS.parse_threshold!(now, nil, site: site)).to eq now - default_duration
        expect(SS.parse_threshold!(now, "", site: site)).to eq now - default_duration
        expect(SS.parse_threshold!(now, 3, site: site)).to eq now - SS::Duration.parse("3.#{site.trash_threshold_unit}")
        expect(SS.parse_threshold!(now, "7.days", site: site)).to eq now - 7.days
        expect(SS.parse_threshold!(now, "2.weeks", site: site)).to eq now - 2.weeks
        expect { SS.parse_threshold!(now, "foobarbaz", site: site) }.to raise_error RuntimeError
        expect { SS.parse_threshold!(now, [], site: site) }.to raise_error ArgumentError
        expect { SS.parse_threshold!(now, [ 1 ], site: site) }.to raise_error ArgumentError
        expect { SS.parse_threshold!(now, {}, site: site) }.to raise_error ArgumentError
        expect { SS.parse_threshold!(now, { key: :value }, site: site) }.to raise_error ArgumentError
      end
    end

    context "with cms site" do
      let!(:site) { create :cms_site_unique }
      it_behaves_like "what parse_threshold! is"
    end

    context "with gws site" do
      let!(:site) { create :gws_group }
      it_behaves_like "what parse_threshold! is"
    end
  end
end
