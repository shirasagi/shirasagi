require 'spec_helper'

describe Cms, dbscope: :example do
  let!(:site) { cms_site }
  let!(:role) { create :cms_role, cur_site: site, permissions: [] }
  let!(:user) { create :cms_test_user, cur_site: site, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }

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

      context "with permission 'edit_sys_users'" do
        let(:resizing) { [ nil, nil ] }

        before do
          sys_user = user.ss_user

          sys_role = create(:sys_role, permissions: %w(edit_sys_users))
          sys_user.update(sys_role_ids: [ sys_role.id ])
        end

        it do
          options = Cms.file_resizing_options(Cms::User.find(user.id), site: site)
          expect(options).to have(10).items

          max_width = max_height = 0
          options.each do |_label, size|
            w, h = size.split(",", 2)
            w = w.strip.to_i
            h = h.strip.to_i
            max_width = w if max_width < w
            max_height = h if max_height < h
          end
          expect(max_width).to eq 1_280
          expect(max_height).to eq 1_280
        end
      end
    end

    context "with cms/image_resizing" do
      let!(:node) { create :article_node_page, cur_site: site }
      let!(:image_resize) do
        create :cms_image_resize, cur_site: site, cur_node: node, state: "enabled", max_width: 1_024, max_height: 1_024
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

      context "with permission 'disable_cms_image_resizes'" do
        let(:resizing) { [ nil, nil ] }

        before do
          role.update(permissions: %w(disable_cms_image_resizes))
        end

        it do
          options = Cms.file_resizing_options(user, site: site, node: node)
          expect(options).to have(10).items

          max_width = max_height = 0
          options.each do |_label, size|
            w, h = size.split(",", 2)
            w = w.strip.to_i
            h = h.strip.to_i
            max_width = w if max_width < w
            max_height = h if max_height < h
          end
          expect(max_width).to eq 1_280
          expect(max_height).to eq 1_280
        end
      end
    end
  end
end
