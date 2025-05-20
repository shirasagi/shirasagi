require 'spec_helper'

describe SS::File, dbscope: :example do
  let!(:site) { cms_site }
  let!(:role) { create :cms_role, cur_site: site, permissions: [] }
  let!(:user) { create :cms_test_user, cur_site: site, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }
  let!(:cms_admin) { cms_user }
  let!(:sys_admin) { sys_user }

  describe ".image_resizes_min_attributes" do
    context "without ss/image_resize" do
      context "without user" do
        it do
          attr = SS::File.image_resizes_min_attributes
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end

      context "with user" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: user)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end

      context "with sys_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: sys_admin)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end

      context "with cms_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: cms_admin)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
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

      context "without user" do
        it do
          attr = SS::File.image_resizes_min_attributes
          expect(attr).to include("max_width" => width1, "max_height" => height1, "quality" => quality1, "size" => be_blank)
        end
      end

      context "with user" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: user)
          expect(attr).to include("max_width" => width1, "max_height" => height1, "quality" => quality1, "size" => be_blank)
        end
      end

      context "with sys_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: sys_admin)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end

      context "with cms_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: cms_admin)
          expect(attr).to include("max_width" => width1, "max_height" => height1, "quality" => quality1, "size" => be_blank)
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

      context "without user" do
        it do
          attr = SS::File.image_resizes_min_attributes
          expect(attr).to include(
            "max_width" => [ width1, width2 ].min, "max_height" => [ height1, height2 ].min,
            "quality" => [ quality1, quality2 ].min, "size" => [ size1, size2 ].min)
        end
      end

      context "with user" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: user)
          expect(attr).to include(
            "max_width" => [ width1, width2 ].min, "max_height" => [ height1, height2 ].min,
            "quality" => [ quality1, quality2 ].min, "size" => [ size1, size2 ].min)
        end
      end

      context "with sys_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: sys_admin)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end

      context "with cms_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: cms_admin)
          expect(attr).to include(
            "max_width" => [ width1, width2 ].min, "max_height" => [ height1, height2 ].min,
            "quality" => [ quality1, quality2 ].min, "size" => [ size1, size2 ].min)
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

      context "without user" do
        it do
          attr = SS::File.image_resizes_min_attributes(node: node)
          expect(attr).to include("max_width" => width1, "max_height" => height1, "quality" => quality1, "size" => be_blank)
        end
      end

      context "with user" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: user, node: node)
          expect(attr).to include("max_width" => width1, "max_height" => height1, "quality" => quality1, "size" => be_blank)
        end
      end

      context "with sys_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: sys_admin, node: node)
          expect(attr).to include("max_width" => width1, "max_height" => height1, "quality" => quality1, "size" => be_blank)
        end
      end

      context "with cms_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: cms_admin, node: node)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
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

      context "without user" do
        it do
          attr = SS::File.image_resizes_min_attributes(node: node)
          expect(attr).to include(
            "max_width" => [ width1, width2 ].min, "max_height" => [ height1, height2 ].min,
            "quality" => [ quality1, quality2 ].min, "size" => [ size1, size2 ].min)
        end
      end

      context "with user" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: user, node: node)
          expect(attr).to include(
            "max_width" => [ width1, width2 ].min, "max_height" => [ height1, height2 ].min,
            "quality" => [ quality1, quality2 ].min, "size" => [ size1, size2 ].min)
        end
      end

      context "with sys_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: sys_admin, node: node)
          expect(attr).to include(
            "max_width" => [ width1, width2 ].min, "max_height" => [ height1, height2 ].min,
            "quality" => [ quality1, quality2 ].min, "size" => [ size1, size2 ].min)
        end
      end

      context "with cms_admin" do
        it do
          attr = SS::File.image_resizes_min_attributes(user: cms_admin, node: node)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end
    end

    context "with ss/image_resize and cms/image_resizing" do
      let(:width1) { rand(800..900) }
      let(:height1) { rand(800..900) }
      let(:quality1) { [ 25, 40, 55, 60, 85 ].sample }
      let(:size1) { rand(1..9) * 1_024 * 1_024 }
      let!(:image_resize1) do
        create :ss_image_resize, state: "enabled", max_width: width1, max_height: height1, quality: quality1, size: size1
      end
      let(:width2) { width1 - 1 }
      let(:height2) { height1 - 1 }
      let(:quality2) { quality1 - 1 }
      let(:size2) { size1 - 1 }
      let!(:image_resize2) do
        create :ss_image_resize, state: "disabled", max_width: width2, max_height: height2, quality: quality2, size: size2
      end

      let!(:node) { create :article_node_page, cur_site: site }
      let(:width3) { rand(800..900) }
      let(:height3) { rand(800..900) }
      let(:quality3) { [ 25, 40, 55, 60, 85 ].sample }
      let(:size3) { rand(1..9) * 1_024 * 1_024 }
      let!(:image_resize3) do
        create(
          :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
          max_width: width3, max_height: height3, quality: quality3, size: size3)
      end
      let(:width4) { width3 - 1 }
      let(:height4) { height3 - 1 }
      let(:quality4) { quality3 - 1 }
      let(:size4) { size3 - 1 }
      let!(:image_resize4) do
        create(
          :cms_image_resize, cur_site: site, cur_node: node, state: "disabled",
          max_width: width4, max_height: height4, quality: quality4, size: size4)
      end

      context "without user" do
        it do
          # このテスト結果は違う気がする......
          # システム側の制限値が小さければ、システム側の制限値になるべきでは？
          attr = SS::File.image_resizes_min_attributes(node: node)
          expect(attr).to include(
            "max_width" => [ width1, width3 ].min, "max_height" => [ height1, height3 ].min,
            "quality" => [ quality1, quality3 ].min, "size" => [ size1, size3 ].min)
        end
      end

      context "with user" do
        it do
          # このテスト結果は違う気がする......
          # システム側の制限値が小さければ、システム側の制限値になるべきでは？
          attr = SS::File.image_resizes_min_attributes(user: user, node: node)
          expect(attr).to include(
            "max_width" => [ width1, width3 ].min, "max_height" => [ height1, height3 ].min,
            "quality" => [ quality1, quality3 ].min, "size" => [ size1, size3 ].min)
        end
      end

      context "with sys_admin" do
        it do
          # このテスト結果は違う気がする......
          # CMS側の画像サイズ制限を無視する権限がないので、CMS側の制限にしたがうべきでは？
          attr = SS::File.image_resizes_min_attributes(user: sys_admin, node: node)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end

      context "with cms_admin" do
        it do
          # このテスト結果は違う気がする......
          # システム側の画像サイズ制限を無視する権限がないので、システム側の制限にしたがうべきでは？
          attr = SS::File.image_resizes_min_attributes(user: cms_admin, node: node)
          expect(attr).to include("max_width" => be_blank, "max_height" => be_blank, "quality" => be_blank, "size" => be_blank)
        end
      end
    end
  end
end
