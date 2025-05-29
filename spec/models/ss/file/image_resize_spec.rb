require 'spec_helper'

describe SS::TempFile, dbscope: :example do
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

  # 800 x 270 の画像を使う（サイズは大きいほど良い）
  let(:path) { "#{Rails.root}/spec/fixtures/cms/line/richmenu_small1.png" }
  let(:in_file) { Rack::Test::UploadedFile.new(path, nil, true) }
  let(:original_dimension) { ::FastImage.size(path) }
  let(:original_width) { original_dimension[0] }
  let(:original_height) { original_dimension[1] }

  context "with ss/image_resize" do
    let(:width1) { 240 }
    let(:height1) { width1 }
    let(:quality1) { 85 }
    let!(:image_resize1) do
      create :ss_image_resize, state: "enabled", max_width: width1, max_height: height1, quality: quality1, size: nil
    end

    context "with user" do
      it do
        item = SS::TempFile.new
        item.cur_user = user
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # user は画像サイズ制限を無効化する権限がないので、
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # 画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width1
        expect(height).to be < height1
      end
    end

    context "with sys_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = sys_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # sys_admin は画像サイズ制限を無効化する権限があるので、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定すると、
          # 画像サイズ制限は適用されない。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = sys_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # sys_admin は画像サイズ制限を無効化する権限があるが、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）が指定されていないので、
          # 画像サイズ制限が適用される。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq width1
          expect(height).to be < height1
        end
      end
    end

    context "with cms_admin" do
      it do
        item = SS::TempFile.new
        item.cur_user = cms_admin
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # cms_admin は画像サイズ制限を無効化する権限がないので、
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # 画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width1
        expect(height).to be < height1
      end
    end

    context "with super_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = super_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin は画像サイズ制限を無効化する権限があるので、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定すると、
          # 画像サイズ制限は適用されない。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = super_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin は画像サイズ制限を無効化する権限があるが、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）が指定されていないので、
          # 画像サイズ制限が適用される。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq width1
          expect(height).to be < height1
        end
      end
    end
  end

  context "with multiple ss/image_resize" do
    let(:width1) { rand(200..300) }
    let(:height1) { width1 }
    let(:quality1) { [ 25, 40, 55, 60, 85 ].sample }
    let!(:image_resize1) do
      create :ss_image_resize, state: "enabled", max_width: width1, max_height: height1, quality: quality1, size: nil
    end
    let(:width2) { rand(200..300) }
    let(:height2) { width2 }
    let(:quality2) { [ 25, 40, 55, 60, 85 ].sample }
    let!(:image_resize2) do
      create :ss_image_resize, state: "enabled", max_width: width2, max_height: height2, quality: quality2, size: nil
    end
    let(:width3) { [ width1, width2 ].min - 1 }
    let(:height3) { width3 }
    let(:quality3) { [ quality1, quality2 ].min - 1 }
    let!(:image_resize3) do
      create :ss_image_resize, state: "disabled", max_width: width3, max_height: height3, quality: quality3, size: nil
    end

    context "with user" do
      it do
        item = SS::TempFile.new
        item.cur_user = user
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # user は画像サイズ制限を無効化する権限がないので、
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # 画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq [ width1, width2 ].min
        expect(height).to be < [ height1, height2 ].min
      end
    end

    context "with sys_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = sys_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # sys_admin は画像サイズ制限を無効化する権限があるので、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定すると、
          # 画像サイズ制限は適用されない。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = sys_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # sys_admin は画像サイズ制限を無効化する権限があるが、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）が指定されていないので、
          # 画像サイズ制限が適用される。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq [ width1, width2 ].min
          expect(height).to be < [ height1, height2 ].min
        end
      end
    end

    context "with cms_admin" do
      it do
        item = SS::TempFile.new
        item.cur_user = cms_admin
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # cms_admin は画像サイズ制限を無効化する権限がないので、
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # 画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq [ width1, width2 ].min
        expect(height).to be < [ height1, height2 ].min
      end
    end

    context "with super_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = super_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin は画像サイズ制限を無効化する権限があるので、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定すると、
          # 画像サイズ制限は適用されない。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = SS::TempFile.new
          item.cur_user = super_admin
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin は画像サイズ制限を無効化する権限があるが、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）が指定されていないので、
          # 画像サイズ制限が適用される。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq [ width1, width2 ].min
          expect(height).to be < [ height1, height2 ].min
        end
      end
    end
  end

  context "with cms/image_resize" do
    let!(:node) { create :article_node_page, cur_site: site }
    let(:width1) { 240 }
    let(:height1) { 240 }
    let(:quality1) { 85 }
    let!(:image_resize1) do
      create(
        :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
        max_width: width1, max_height: height1, quality: quality1, size: nil)
    end

    context "with user" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = user
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        width, height = ::FastImage.size(item.path)
        expect(width).to eq 240
        expect(height).to be < 240
      end
    end

    context "with sys_admin" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = sys_admin
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        width, height = ::FastImage.size(item.path)
        expect(width).to eq 240
        expect(height).to be < 240
      end
    end

    context "with cms_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = cms_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = cms_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq 240
          expect(height).to be < 240
        end
      end
    end

    context "with super_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq 240
          expect(height).to be < 240
        end
      end
    end
  end

  context "with multiple cms/image_resize" do
    let!(:node) { create :article_node_page, cur_site: site }
    let(:width1) { rand(200..300) }
    let(:height1) { width1 }
    let(:quality1) { [ 25, 40, 55, 60, 85 ].sample }
    let!(:image_resize1) do
      create(
        :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
        max_width: width1, max_height: height1, quality: quality1, size: nil)
    end
    let(:width2) { rand(200..300) }
    let(:height2) { width2 }
    let(:quality2) { [ 25, 40, 55, 60, 85 ].sample }
    let!(:image_resize2) do
      create(
        :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
        max_width: width2, max_height: height2, quality: quality2, size: nil)
    end
    let(:width3) { [ width1, width2 ].min - 1 }
    let(:height3) { width3 }
    let(:quality3) { [ quality1, quality2 ].min - 1 }
    let!(:image_resize3) do
      create(
        :cms_image_resize, cur_site: site, cur_node: node, state: "disabled",
        max_width: width3, max_height: height3, quality: quality3, size: nil)
    end

    context "with user" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = user
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        width, height = ::FastImage.size(item.path)
        expect(width).to eq [ width1, width2 ].min
        expect(height).to be < [ height1, height2 ].min
      end
    end

    context "with sys_admin" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = sys_admin
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        width, height = ::FastImage.size(item.path)
        expect(width).to eq [ width1, width2 ].min
        expect(height).to be < [ height1, height2 ].min
      end
    end

    context "with cms_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = cms_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = cms_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq [ width1, width2 ].min
          expect(height).to be < [ height1, height2 ].min
        end
      end
    end

    context "with super_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          width, height = ::FastImage.size(item.path)
          expect(width).to eq [ width1, width2 ].min
          expect(height).to be < [ height1, height2 ].min
        end
      end
    end
  end

  context "ss/image_resize is looser than cms/image_resize" do
    let(:width1) { rand(301..400) }
    let(:height1) { width1 }
    let(:quality1) { rand(81..90) }
    let!(:image_resize1) do
      create(:ss_image_resize, state: "enabled", max_width: width1, max_height: height1, quality: quality1, size: nil)
    end
    let!(:node) { create :article_node_page, cur_site: site }
    let(:width2) { rand(201..300) }
    let(:height2) { width2 }
    let(:quality2) { rand(61..70) }
    let!(:image_resize2) do
      create(
        :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
        max_width: width2, max_height: height2, quality: quality2, size: nil)
    end

    context "with user" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = user
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # user は画像サイズ制限を無効化する権限がないので、
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # 画像サイズ制限が適用される。適用される制限は小さい方。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width2
        expect(height).to be < height2
      end
    end

    context "with sys_admin" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = sys_admin
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # sys_admin はシステムの画像サイズ制限を無効化する権限があるが、CMSの画像サイズ制限を無効化する権限がない。
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # CMSの画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width2
        expect(height).to be < height2
      end
    end

    context "with cms_admin" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = cms_admin
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # cms_admin はシステムの画像サイズ制限を無効化する権限はないが、CMSの画像サイズ制限を無効化する権限がある。
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # システムの画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width1
        expect(height).to be < height1
      end
    end

    context "with super_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin はシステムの画像サイズ制限を無効化する権限があり、CMSの画像サイズ制限を無効化する権限もある。
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定すると、
          # 画像サイズ制限は適用されない。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin はシステムの画像サイズ制限を無効化する権限があり、CMSの画像サイズ制限を無効化する権限もあるが、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）が指定されていないので、
          # 画像サイズ制限が適用される。適用される制限は小さい方。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq width2
          expect(height).to be < height2
        end
      end
    end
  end

  context "ss/image_resize is tighter than cms/image_resize" do
    let(:width1) { rand(201..300) }
    let(:height1) { width2 }
    let(:quality1) { rand(61..70) }
    let!(:image_resize1) do
      create(:ss_image_resize, state: "enabled", max_width: width1, max_height: height1, quality: quality1, size: nil)
    end
    let!(:node) { create :article_node_page, cur_site: site }
    let(:width2) { rand(301..400) }
    let(:height2) { width1 }
    let(:quality2) { rand(81..90) }
    let!(:image_resize2) do
      create(
        :cms_image_resize, cur_site: site, cur_node: node, state: "enabled",
        max_width: width2, max_height: height2, quality: quality2, size: nil)
    end

    context "with user" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = user
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # user は画像サイズ制限を無効化する権限がないので、
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # 画像サイズ制限が適用される。適用される制限は小さい方。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width1
        expect(height).to be < height1
      end
    end

    context "with sys_admin" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = sys_admin
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # sys_admin はシステムの画像サイズ制限を無効化する権限があるが、CMSの画像サイズ制限を無効化する権限がない。
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # CMSの画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width2
        expect(height).to be < height2
      end
    end

    context "with cms_admin" do
      it do
        item = Cms::TempFile.new
        item.cur_site = site
        item.cur_user = cms_admin
        item.cur_node = node
        # item.resizing = resizing
        # item.quality = quality
        item.image_resizes_disabled = "disabled"
        item.in_file = in_file

        result = item.save
        expect(result).to be_truthy

        # cms_admin はシステムの画像サイズ制限を無効化する権限はないが、CMSの画像サイズ制限を無効化する権限がある。
        # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定しても、
        # システムの画像サイズ制限が適用される。
        width, height = ::FastImage.size(item.path)
        expect(width).to eq width1
        expect(height).to be < height1
      end
    end

    context "with super_admin" do
      context "when image_resizes_disabled is 'disabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "disabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin はシステムの画像サイズ制限を無効化する権限があり、CMSの画像サイズ制限を無効化する権限もある。
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）を指定すると、
          # 画像サイズ制限は適用されない。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq original_width
          expect(height).to eq original_height
        end
      end

      context "when image_resizes_disabled is 'enabled'" do
        it do
          item = Cms::TempFile.new
          item.cur_site = site
          item.cur_user = super_admin
          item.cur_node = node
          # item.resizing = resizing
          # item.quality = quality
          item.image_resizes_disabled = "enabled"
          item.in_file = in_file

          result = item.save
          expect(result).to be_truthy

          # super_admin はシステムの画像サイズ制限を無効化する権限があり、CMSの画像サイズ制限を無効化する権限もあるが、
          # 画像サイズ制限を無視するオプション（image_resizes_disabled = "disabled"）が指定されていないので、
          # 画像サイズ制限が適用される。適用される制限は小さい方。
          width, height = ::FastImage.size(item.path)
          expect(width).to eq width1
          expect(height).to be < height1
        end
      end
    end
  end
end
