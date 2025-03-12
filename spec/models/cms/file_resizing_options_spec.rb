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

    context "with ss/image_resizing" do
      let!(:image_resize) { create :ss_image_resize, state: "enabled", max_width: 1_024, max_height: 1_024 }

      context "resizing equals to ss/image_resizing" do
        let(:resizing) { [ image_resize.max_width, image_resize.max_height ] }

        it do
          options = Cms.file_resizing_options(user, site: site)
          expect(options).to have(9).items

          label = site.t(:file_resizing_label, size: resizing.join("x"))
          value = resizing.join(",")
          expect(options).to include([ label, value, { selected: true } ])
        end
      end

      context "resizing is over ss/image_resizing" do
        let(:resizing) { [ image_resize.max_width + 1, image_resize.max_height + 1 ] }

        it do
          options = Cms.file_resizing_options(user, site: site)
          expect(options).to have(8).items

          label = site.t(:file_resizing_label, size: resizing.join("x"))
          value = resizing.join(",")
          expect(options).not_to include([ label, value, { selected: true } ])
        end
      end
    end

    context "with cms/image_resizing" do
      let!(:node) { create :article_node_page, cur_site: site }
      let!(:image_resize) do
        create :cms_image_resize, cur_site: site, cur_node: node, state: "enabled", max_width: 1_024, max_height: 1_024
      end

      before do
        user.cms_roles.each do |role|
          role.permissions = role.permissions - %w(disable_cms_image_resizes)
          role.save!
        end
      end

      context "resizing equals to cms/image_resizing" do
        let(:resizing) { [ image_resize.max_width, image_resize.max_height ] }

        it do
          options = Cms.file_resizing_options(user, site: site, node: node)
          expect(options).to have(9).items

          label = site.t(:file_resizing_label, size: resizing.join("x"))
          value = resizing.join(",")
          expect(options).to include([ label, value, { selected: true } ])
        end
      end

      context "resizing is over cms/image_resizing" do
        let(:resizing) { [ image_resize.max_width + 1, image_resize.max_height + 1 ] }

        it do
          options = Cms.file_resizing_options(user, site: site, node: node)
          expect(options).to have(8).items

          label = site.t(:file_resizing_label, size: resizing.join("x"))
          value = resizing.join(",")
          expect(options).not_to include([ label, value, { selected: true } ])
        end
      end
    end
  end
end
