require 'spec_helper'

describe Cms, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  describe ".file_resizing_options" do
    before do
      site.in_file_resizing_width = resizing[0]
      site.in_file_resizing_height = resizing[1]
      site.save!
    end

    context "with unique resizing" do
      let(:resizing) { [ 357, 357 ] }

      it do
        options = Cms.file_resizing_options(user, site: site)
        expect(options).to have(11).items

        label = site.t(:file_resizing_label, size: resizing.join("x"))
        value = resizing.join(",")
        expect(options).to include([ label, value, { selected: true } ])
      end
    end

    context "with nil" do
      let(:resizing) { [ nil, nil ] }

      it do
        options = Cms.file_resizing_options(user, site: site)
        expect(options).to have(10).items
      end
    end

    context "with existing resizing" do
      let(:resizing) { [ 640, 480 ] }

      it do
        options = Cms.file_resizing_options(user, site: site)
        expect(options).to have(10).items

        label = site.t(:file_resizing_label, size: resizing.join("x"))
        value = resizing.join(",")
        expect(options).to include([ label, value, { selected: true } ])
      end
    end
  end
end
