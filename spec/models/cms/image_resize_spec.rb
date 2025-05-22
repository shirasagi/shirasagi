require 'spec_helper'

describe Cms::ImageResize, type: :model, dbscope: :example do
  describe ".intersection" do
    it do
      lhs = Cms::ImageResize.new
      rhs = Cms::ImageResize.new
      result = Cms::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(Cms::ImageResize)
      expect(result.max_width).to be_blank
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = Cms::ImageResize.new(max_width: 100)
      rhs = Cms::ImageResize.new(max_width: 200)
      result = Cms::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(Cms::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = Cms::ImageResize.new(max_width: 200)
      rhs = Cms::ImageResize.new(max_width: 100)
      result = Cms::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(Cms::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = Cms::ImageResize.new
      rhs = Cms::ImageResize.new(max_width: 200)
      result = Cms::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(Cms::ImageResize)
      expect(result.max_width).to eq 200
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      rhs = Cms::ImageResize.new(max_width: 200)
      result = Cms::ImageResize.intersection(nil, rhs)
      expect(result).to be_a(Cms::ImageResize)
      expect(result.max_width).to eq 200
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = Cms::ImageResize.new(max_width: 100)
      rhs = Cms::ImageResize.new
      result = Cms::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(Cms::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = Cms::ImageResize.new(max_width: 100)
      result = Cms::ImageResize.intersection(lhs, nil)
      expect(result).to be_a(Cms::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end
  end

  describe ".effective_resize" do
    let!(:site) { cms_site }
    let!(:role) { create :cms_role, cur_site: site, permissions: [] }
    let!(:user) { create :cms_test_user, cur_site: site, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }
    let!(:cms_admin) { cms_user }
    let!(:node) { create :article_node_page, cur_site: site }

    context "when there are no ss/image_resize items" do
      it do
        expect(Cms::ImageResize.effective_resize(node: node, user: user)).to be_blank
        expect(Cms::ImageResize.effective_resize(node: node, user: cms_admin)).to be_blank
        expect(Cms::ImageResize.effective_resize(node: node, user: user, request_disable: true)).to be_blank
        expect(Cms::ImageResize.effective_resize(node: node, user: cms_admin, request_disable: true)).to be_blank
      end
    end

    context "when there is a ss/image_resize item" do
      let!(:image_resize) { create :cms_image_resize, cur_site: site, cur_node: node, state: 'enabled' }

      it do
        Cms::ImageResize.effective_resize(node: node, user: user).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq image_resize.max_width
          expect(effective.max_height).to eq image_resize.max_height
          expect(effective.quality).to eq image_resize.quality
          expect(effective.size).to eq image_resize.size
        end

        Cms::ImageResize.effective_resize(node: node, user: cms_admin).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq image_resize.max_width
          expect(effective.max_height).to eq image_resize.max_height
          expect(effective.quality).to eq image_resize.quality
          expect(effective.size).to eq image_resize.size
        end

        Cms::ImageResize.effective_resize(node: node, user: user, request_disable: true).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq image_resize.max_width
          expect(effective.max_height).to eq image_resize.max_height
          expect(effective.quality).to eq image_resize.quality
          expect(effective.size).to eq image_resize.size
        end

        Cms::ImageResize.effective_resize(node: node, user: cms_admin, request_disable: true).tap do |effective|
          expect(effective).to be_blank
        end
      end
    end

    context "when there is 2 ss/image_resize items" do
      let!(:image_resize1) { create :cms_image_resize, cur_site: site, cur_node: node, state: 'enabled' }
      let!(:image_resize2) { create :cms_image_resize, cur_site: site, cur_node: node, state: 'enabled' }

      it do
        Cms::ImageResize.effective_resize(node: node, user: user).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq [ image_resize1.max_width, image_resize2.max_width ].min
          expect(effective.max_height).to eq [ image_resize1.max_height, image_resize2.max_height ].min
          expect(effective.quality).to eq [ image_resize1.quality, image_resize2.quality ].min
          expect(effective.size).to eq [ image_resize1.size, image_resize2.size ].min
        end

        Cms::ImageResize.effective_resize(node: node, user: cms_admin).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq [ image_resize1.max_width, image_resize2.max_width ].min
          expect(effective.max_height).to eq [ image_resize1.max_height, image_resize2.max_height ].min
          expect(effective.quality).to eq [ image_resize1.quality, image_resize2.quality ].min
          expect(effective.size).to eq [ image_resize1.size, image_resize2.size ].min
        end

        Cms::ImageResize.effective_resize(node: node, user: user, request_disable: true).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq [ image_resize1.max_width, image_resize2.max_width ].min
          expect(effective.max_height).to eq [ image_resize1.max_height, image_resize2.max_height ].min
          expect(effective.quality).to eq [ image_resize1.quality, image_resize2.quality ].min
          expect(effective.size).to eq [ image_resize1.size, image_resize2.size ].min
        end

        Cms::ImageResize.effective_resize(node: node, user: cms_admin, request_disable: true).tap do |effective|
          expect(effective).to be_blank
        end
      end
    end

    context "when there is 2 ss/image_resize items but one is disabled" do
      let!(:site) { cms_site }
      let!(:role) { create :cms_role, cur_site: site, permissions: [] }
      let!(:user) { create :cms_test_user, cur_site: site, group_ids: cms_user.group_ids, cms_role_ids: [ role.id ] }
      let!(:cms_admin) { cms_user }
      let!(:image_resize1) { create :cms_image_resize, cur_site: site, cur_node: node, state: 'enabled' }
      let!(:image_resize2) { create :cms_image_resize, cur_site: site, cur_node: node, state: 'disabled' }

      it do
        Cms::ImageResize.effective_resize(node: node, user: user).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq image_resize1.max_width
          expect(effective.max_height).to eq image_resize1.max_height
          expect(effective.quality).to eq image_resize1.quality
          expect(effective.size).to eq image_resize1.size
        end

        Cms::ImageResize.effective_resize(node: node, user: cms_admin).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq image_resize1.max_width
          expect(effective.max_height).to eq image_resize1.max_height
          expect(effective.quality).to eq image_resize1.quality
          expect(effective.size).to eq image_resize1.size
        end

        Cms::ImageResize.effective_resize(node: node, user: user, request_disable: true).tap do |effective|
          expect(effective).to be_a(Cms::ImageResize)
          expect(effective.max_width).to eq image_resize1.max_width
          expect(effective.max_height).to eq image_resize1.max_height
          expect(effective.quality).to eq image_resize1.quality
          expect(effective.size).to eq image_resize1.size
        end

        Cms::ImageResize.effective_resize(node: node, user: cms_admin, request_disable: true).tap do |effective|
          expect(effective).to be_blank
        end
      end
    end
  end
end
