require 'spec_helper'

describe SS::File, dbscope: :example do
  let!(:site) { cms_site }
  let!(:role) { create :cms_role, cur_site: site, permissions: [] }
  let!(:user) { create :cms_test_user, cur_site: site, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }
  let!(:cms_admin) { cms_user }
  let!(:sys_admin) { sys_user }
  let!(:super_admin) do
    # sys でも cms でもスーパーなユーザー
    user = create :cms_test_user, cur_site: site, group_ids: cms_admin.group_ids, cms_role_ids: cms_admin.cms_role_ids
    user.update(sys_role_ids: sys_admin.sys_role_ids)
    Cms::User.find(user.id)
  end

  describe ".effective_image_resize" do
    context "without ss/image_resize" do
      context "with user" do
        it do
          SS::File.effective_image_resize(user: user).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: user, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end

      context "with sys_admin" do
        it do
          SS::File.effective_image_resize(user: sys_admin).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: sys_admin, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end

      context "with cms_admin" do
        it do
          SS::File.effective_image_resize(user: cms_admin).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: cms_admin, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end

      context "with super_admin" do
        it do
          SS::File.effective_image_resize(user: super_admin.cms_user).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: super_admin.ss_user).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: super_admin.cms_user, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: super_admin.ss_user, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end
    end

    context "with ss/image_resize" do
      let(:width1) { 800 }
      let(:height1) { 800 }
      let(:quality1) { 85 }
      let!(:image_resize1) do
        create :ss_image_resize, state: "enabled", max_width: width1, max_height: height1, quality: quality1, size: nil
      end

      context "with user" do
        it do
          SS::File.effective_image_resize(user: user).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: user, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end
        end
      end

      context "with sys_admin" do
        it do
          SS::File.effective_image_resize(user: sys_admin).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: sys_admin, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end

      context "with cms_admin" do
        it do
          SS::File.effective_image_resize(user: cms_admin).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: cms_admin, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end
        end
      end

      context "with super_admin" do
        it do
          SS::File.effective_image_resize(user: super_admin.cms_user).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: super_admin.ss_user).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: super_admin.cms_user, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: super_admin.ss_user, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end
    end

    context "with multiple ss/image_resize" do
      let(:width1) { rand(800..900) }
      let(:height1) { rand(800..900) }
      let(:quality1) { [ 25, 40, 55, 60, 85 ].sample }
      let(:size1) { rand(1..9) * 1_024 * 1_024 }
      let!(:image_resize1) do
        create :ss_image_resize, state: "enabled", max_width: width1, max_height: height1, quality: quality1, size: size1
      end
      let(:width2) { rand(800..900) }
      let(:height2) { rand(800..900) }
      let(:quality2) { [ 25, 40, 55, 60, 85 ].sample }
      let(:size2) { rand(1..9) * 1_024 * 1_024 }
      let!(:image_resize2) do
        create :ss_image_resize, state: "enabled", max_width: width2, max_height: height2, quality: quality2, size: size2
      end
      let(:width3) { rand(800..900) }
      let(:height3) { rand(800..900) }
      let(:quality3) { [ 25, 40, 55, 60, 85 ].sample }
      let(:size3) { rand(1..9) * 1_024 * 1_024 }
      let!(:image_resize3) do
        create :ss_image_resize, state: "disabled", max_width: width3, max_height: height3, quality: quality3, size: size3
      end

      context "with user" do
        it do
          SS::File.effective_image_resize(user: user).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: user, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end
        end
      end

      context "with sys_admin" do
        it do
          SS::File.effective_image_resize(user: sys_admin).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: sys_admin, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end

      context "with cms_admin" do
        it do
          SS::File.effective_image_resize(user: cms_admin).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: cms_admin, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end
        end
      end

      context "with super_admin" do
        it do
          SS::File.effective_image_resize(user: super_admin.cms_user).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: super_admin.ss_user).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: super_admin.cms_user, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: super_admin.ss_user, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end
    end

    context "with cms/image_resizing" do
      let!(:node) { create :article_node_page, cur_site: site }
      let(:width1) { 800 }
      let(:height1) { 800 }
      let(:quality1) { 85 }
      let!(:image_resize) do
        create(
          :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
          max_width: width1, max_height: height1, quality: quality1, size: nil)
      end

      context "with user" do
        it do
          SS::File.effective_image_resize(user: user, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: user, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end
        end
      end

      context "with sys_admin" do
        it do
          SS::File.effective_image_resize(user: sys_admin, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: sys_admin, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end
        end
      end

      context "with cms_admin" do
        it do
          SS::File.effective_image_resize(user: cms_admin, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: cms_admin, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end

      context "with super_admin" do
        it do
          SS::File.effective_image_resize(user: super_admin.cms_user, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: super_admin.ss_user, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq width1
            expect(min_resize.max_height).to eq height1
            expect(min_resize.quality).to eq quality1
            expect(min_resize.size).to be_nil
          end

          SS::File.effective_image_resize(user: super_admin.cms_user, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: super_admin.ss_user, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end
    end

    context "with multiple cms/image_resizing" do
      let!(:node) { create :article_node_page, cur_site: site }
      let(:width1) { rand(800..900) }
      let(:height1) { rand(800..900) }
      let(:quality1) { [ 25, 40, 55, 60, 85 ].sample }
      let(:size1) { rand(1..9) * 1_024 * 1_024 }
      let!(:image_resize1) do
        create(
          :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
          max_width: width1, max_height: height1, quality: quality1, size: size1)
      end
      let(:width2) { rand(800..900) }
      let(:height2) { rand(800..900) }
      let(:quality2) { [ 25, 40, 55, 60, 85 ].sample }
      let(:size2) { rand(1..9) * 1_024 * 1_024 }
      let!(:image_resize2) do
        create(
          :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
          max_width: width2, max_height: height2, quality: quality2, size: size2)
      end
      let(:width3) { [ width1, width2 ].min - 1 }
      let(:height3) { [ height1, height2 ].min - 1 }
      let(:quality3) { [ quality1, quality2 ].min - 1 }
      let(:size3) { [ size1, size2 ].min - 1 }
      let!(:image_resize3) do
        create(
          :cms_image_resize, cur_site: site, cur_node: node, state: "disabled",
          max_width: width3, max_height: height3, quality: quality3, size: size3)
      end

      context "with user" do
        it do
          SS::File.effective_image_resize(user: user, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: user, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end
        end
      end

      context "with sys_admin" do
        it do
          SS::File.effective_image_resize(user: sys_admin, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: sys_admin, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end
        end
      end

      context "with cms_admin" do
        it do
          SS::File.effective_image_resize(user: cms_admin, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: cms_admin, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end

      context "with super_admin" do
        it do
          SS::File.effective_image_resize(user: super_admin.cms_user, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: super_admin.ss_user, node: node).tap do |min_resize|
            expect(min_resize.max_width).to eq [ width1, width2 ].min
            expect(min_resize.max_height).to eq [ height1, height2 ].min
            expect(min_resize.quality).to eq [ quality1, quality2 ].min
            expect(min_resize.size).to eq [ size1, size2 ].min
          end

          SS::File.effective_image_resize(user: super_admin.cms_user, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end

          SS::File.effective_image_resize(user: super_admin.ss_user, node: node, request_disable: true).tap do |min_resize|
            expect(min_resize).to be_blank
          end
        end
      end
    end

    context "with ss/image_resize and cms/image_resizing" do
      context "ss/image_resize is bigger / looser than cms/image_resizing" do
        let(:sys_width1) { rand(851..900) }
        let(:sys_height1) { rand(851..900) }
        let(:sys_quality1) { [ 60, 85 ].sample }
        let(:sys_size1) { rand(5..9) * 1_024 * 1_024 }
        let!(:image_resize1) do
          create(
            :ss_image_resize, state: "enabled",
            max_width: sys_width1, max_height: sys_height1, quality: sys_quality1, size: sys_size1)
        end
        let(:sys_width2) { sys_width1 - 1 }
        let(:sys_height2) { sys_height1 - 1 }
        let(:sys_quality2) { sys_quality1 - 1 }
        let(:sys_size2) { sys_size1 - 1 }
        let!(:image_resize2) do
          create(
            :ss_image_resize, state: "disabled",
            max_width: sys_width2, max_height: sys_height2, quality: sys_quality2, size: sys_size2)
        end

        let!(:node) { create :article_node_page, cur_site: site }
        let(:cms_width1) { rand(751..800) }
        let(:cms_height1) { rand(751..800) }
        let(:cms_quality1) { [ 25, 40, 55 ].sample }
        let(:cms_size1) { rand(1..4) * 1_024 * 1_024 }
        let!(:image_resize3) do
          create(
            :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
            max_width: cms_width1, max_height: cms_height1, quality: cms_quality1, size: cms_size1)
        end
        let(:cms_width2) { cms_width1 - 1 }
        let(:cms_height2) { cms_height1 - 1 }
        let(:cms_quality2) { cms_quality1 - 1 }
        let(:cms_size2) { cms_size1 - 1 }
        let!(:image_resize4) do
          create(
            :cms_image_resize, cur_site: site, cur_node: node, state: "disabled",
            max_width: cms_width2, max_height: cms_height2, quality: cms_quality2, size: cms_size2)
        end

        context "with user" do
          it do
            SS::File.effective_image_resize(user: user, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end

            SS::File.effective_image_resize(user: user, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end
          end
        end

        context "with sys_admin" do
          it do
            SS::File.effective_image_resize(user: sys_admin, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end

            SS::File.effective_image_resize(user: sys_admin, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end
          end
        end

        context "with cms_admin" do
          it do
            SS::File.effective_image_resize(user: cms_admin, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end

            SS::File.effective_image_resize(user: cms_admin, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end
          end
        end

        context "with super_admin" do
          it do
            SS::File.effective_image_resize(user: super_admin.cms_user, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end

            SS::File.effective_image_resize(user: super_admin.ss_user, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end

            SS::File.effective_image_resize(user: super_admin.cms_user, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize).to be_blank
            end

            SS::File.effective_image_resize(user: super_admin.ss_user, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize).to be_blank
            end
          end
        end
      end

      context "ss/image_resize is smaller / tighter than cms/image_resizing" do
        let(:sys_width1) { rand(751..800) }
        let(:sys_height1) { rand(751..800) }
        let(:sys_quality1) { [ 25, 40, 55 ].sample }
        let(:sys_size1) { rand(1..4) * 1_024 * 1_024 }
        let!(:image_resize1) do
          create(
            :ss_image_resize, state: "enabled",
            max_width: sys_width1, max_height: sys_height1, quality: sys_quality1, size: sys_size1)
        end
        let(:sys_width2) { sys_width1 - 1 }
        let(:sys_height2) { sys_height1 - 1 }
        let(:sys_quality2) { sys_quality1 - 1 }
        let(:sys_size2) { sys_size1 - 1 }
        let!(:image_resize2) do
          create(
            :ss_image_resize, state: "disabled",
            max_width: sys_width2, max_height: sys_height2, quality: sys_quality2, size: sys_size2)
        end

        let!(:node) { create :article_node_page, cur_site: site }
        let(:cms_width1) { rand(851..900) }
        let(:cms_height1) { rand(851..900) }
        let(:cms_quality1) { [ 60, 85 ].sample }
        let(:cms_size1) { rand(5..9) * 1_024 * 1_024 }
        let!(:image_resize3) do
          create(
            :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
            max_width: cms_width1, max_height: cms_height1, quality: cms_quality1, size: cms_size1)
        end
        let(:cms_width2) { cms_width1 - 1 }
        let(:cms_height2) { cms_height1 - 1 }
        let(:cms_quality2) { cms_quality1 - 1 }
        let(:cms_size2) { cms_size1 - 1 }
        let!(:image_resize4) do
          create(
            :cms_image_resize, cur_site: site, cur_node: node, state: "disabled",
            max_width: cms_width2, max_height: cms_height2, quality: cms_quality2, size: cms_size2)
        end

        context "with user" do
          it do
            SS::File.effective_image_resize(user: user, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end

            SS::File.effective_image_resize(user: user, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end
          end
        end

        context "with sys_admin" do
          it do
            SS::File.effective_image_resize(user: sys_admin, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end

            SS::File.effective_image_resize(user: sys_admin, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize.max_width).to eq cms_width1
              expect(min_resize.max_height).to eq cms_height1
              expect(min_resize.quality).to eq cms_quality1
              expect(min_resize.size).to eq cms_size1
            end
          end
        end

        context "with cms_admin" do
          it do
            SS::File.effective_image_resize(user: cms_admin, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end

            SS::File.effective_image_resize(user: cms_admin, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end
          end
        end

        context "with super_admin" do
          it do
            SS::File.effective_image_resize(user: super_admin.cms_user, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end

            SS::File.effective_image_resize(user: super_admin.ss_user, node: node).tap do |min_resize|
              expect(min_resize.max_width).to eq sys_width1
              expect(min_resize.max_height).to eq sys_height1
              expect(min_resize.quality).to eq sys_quality1
              expect(min_resize.size).to eq sys_size1
            end

            SS::File.effective_image_resize(user: super_admin.cms_user, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize).to be_blank
            end

            SS::File.effective_image_resize(user: super_admin.ss_user, node: node, request_disable: true).tap do |min_resize|
              expect(min_resize).to be_blank
            end
          end
        end
      end
    end
  end
end
