require 'spec_helper'

describe SS::ImageResize, type: :model, dbscope: :example do
  describe ".intersection" do
    it do
      lhs = SS::ImageResize.new
      rhs = SS::ImageResize.new
      result = SS::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(SS::ImageResize)
      expect(result.max_width).to be_blank
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = SS::ImageResize.new(max_width: 100)
      rhs = SS::ImageResize.new(max_width: 200)
      result = SS::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(SS::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = SS::ImageResize.new(max_width: 200)
      rhs = SS::ImageResize.new(max_width: 100)
      result = SS::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(SS::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = SS::ImageResize.new
      rhs = SS::ImageResize.new(max_width: 200)
      result = SS::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(SS::ImageResize)
      expect(result.max_width).to eq 200
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      rhs = SS::ImageResize.new(max_width: 200)
      result = SS::ImageResize.intersection(nil, rhs)
      expect(result).to be_a(SS::ImageResize)
      expect(result.max_width).to eq 200
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = SS::ImageResize.new(max_width: 100)
      rhs = SS::ImageResize.new
      result = SS::ImageResize.intersection(lhs, rhs)
      expect(result).to be_a(SS::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end

    it do
      lhs = SS::ImageResize.new(max_width: 100)
      result = SS::ImageResize.intersection(lhs, nil)
      expect(result).to be_a(SS::ImageResize)
      expect(result.max_width).to eq 100
      expect(result.max_height).to be_blank
      expect(result.size).to be_blank
      expect(result.quality).to be_blank
    end
  end

  describe ".effective_resize" do
    let!(:user) { create :sys_user_sample }
    let!(:sys_admin) { sys_user }

    context "when there are no ss/image_resize items" do
      it do
        expect(SS::ImageResize.effective_resize(user: user)).to be_blank
        expect(SS::ImageResize.effective_resize(user: sys_admin)).to be_blank
        expect(SS::ImageResize.effective_resize(user: user, request_disable: true)).to be_blank
        expect(SS::ImageResize.effective_resize(user: sys_admin, request_disable: true)).to be_blank
      end
    end

    context "when there is a ss/image_resize item" do
      let!(:image_resize) { create :ss_image_resize, state: 'enabled' }

      it do
        SS::ImageResize.effective_resize(user: user).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq image_resize.max_width
          expect(effective.max_height).to eq image_resize.max_height
          expect(effective.quality).to eq image_resize.quality
          expect(effective.size).to eq image_resize.size
        end

        SS::ImageResize.effective_resize(user: sys_admin).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq image_resize.max_width
          expect(effective.max_height).to eq image_resize.max_height
          expect(effective.quality).to eq image_resize.quality
          expect(effective.size).to eq image_resize.size
        end

        SS::ImageResize.effective_resize(user: user, request_disable: true).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq image_resize.max_width
          expect(effective.max_height).to eq image_resize.max_height
          expect(effective.quality).to eq image_resize.quality
          expect(effective.size).to eq image_resize.size
        end

        SS::ImageResize.effective_resize(user: sys_admin, request_disable: true).tap do |effective|
          expect(effective).to be_blank
        end
      end
    end

    context "when there is 2 ss/image_resize items" do
      let!(:image_resize1) { create :ss_image_resize, state: 'enabled' }
      let!(:image_resize2) { create :ss_image_resize, state: 'enabled' }

      it do
        SS::ImageResize.effective_resize(user: user).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq [ image_resize1.max_width, image_resize2.max_width ].min
          expect(effective.max_height).to eq [ image_resize1.max_height, image_resize2.max_height ].min
          expect(effective.quality).to eq [ image_resize1.quality, image_resize2.quality ].min
          expect(effective.size).to eq [ image_resize1.size, image_resize2.size ].min
        end

        SS::ImageResize.effective_resize(user: sys_admin).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq [ image_resize1.max_width, image_resize2.max_width ].min
          expect(effective.max_height).to eq [ image_resize1.max_height, image_resize2.max_height ].min
          expect(effective.quality).to eq [ image_resize1.quality, image_resize2.quality ].min
          expect(effective.size).to eq [ image_resize1.size, image_resize2.size ].min
        end

        SS::ImageResize.effective_resize(user: user, request_disable: true).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq [ image_resize1.max_width, image_resize2.max_width ].min
          expect(effective.max_height).to eq [ image_resize1.max_height, image_resize2.max_height ].min
          expect(effective.quality).to eq [ image_resize1.quality, image_resize2.quality ].min
          expect(effective.size).to eq [ image_resize1.size, image_resize2.size ].min
        end

        SS::ImageResize.effective_resize(user: sys_admin, request_disable: true).tap do |effective|
          expect(effective).to be_blank
        end
      end
    end

    context "when there is 2 ss/image_resize items but one is disabled" do
      let!(:image_resize1) { create :ss_image_resize, state: 'enabled' }
      let!(:image_resize2) { create :ss_image_resize, state: 'disabled' }

      it do
        SS::ImageResize.effective_resize(user: user).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq image_resize1.max_width
          expect(effective.max_height).to eq image_resize1.max_height
          expect(effective.quality).to eq image_resize1.quality
          expect(effective.size).to eq image_resize1.size
        end

        SS::ImageResize.effective_resize(user: sys_admin).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq image_resize1.max_width
          expect(effective.max_height).to eq image_resize1.max_height
          expect(effective.quality).to eq image_resize1.quality
          expect(effective.size).to eq image_resize1.size
        end

        SS::ImageResize.effective_resize(user: user, request_disable: true).tap do |effective|
          expect(effective).to be_a(SS::ImageResize)
          expect(effective.max_width).to eq image_resize1.max_width
          expect(effective.max_height).to eq image_resize1.max_height
          expect(effective.quality).to eq image_resize1.quality
          expect(effective.size).to eq image_resize1.size
        end

        SS::ImageResize.effective_resize(user: sys_admin, request_disable: true).tap do |effective|
          expect(effective).to be_blank
        end
      end
    end
  end

  context "validities" do
    describe "#state" do
      it do
        item = SS::ImageResize.new
        expect(item).to be_invalid
        expect(item.errors[:state]).to be_blank
      end

      it do
        item = SS::ImageResize.new
        item.state = unique_id
        expect(item).to be_invalid
        expect(item.errors[:state]).to eq [ I18n.t("errors.messages.inclusion") ]
      end
    end

    describe "#max_width" do
      it do
        item = SS::ImageResize.new
        expect(item).to be_invalid
        expect(item.errors[:max_width]).to eq [ I18n.t("errors.messages.blank") ]
        expect(item.errors[:max_height]).to eq [ I18n.t("errors.messages.blank") ]
      end

      it do
        item = SS::ImageResize.new
        item.max_width = -1
        expect(item).to be_invalid
        expect(item.errors[:max_width]).to eq [ I18n.t("errors.messages.greater_than", count: 0) ]
      end

      it do
        item = SS::ImageResize.new
        item.max_width = 0
        expect(item).to be_invalid
        expect(item.errors[:max_width]).to eq [ I18n.t("errors.messages.greater_than", count: 0) ]
      end

      it do
        item = SS::ImageResize.new
        item.max_width = 2_147_483_647 # Integer::MAX
        expect(item).to be_invalid
        expect(item.errors[:max_width]).to be_blank
      end
    end

    describe "#size" do
      it do
        item = SS::ImageResize.new
        expect(item).to be_invalid
        expect(item.errors[:size]).to be_blank
      end

      it do
        item = SS::ImageResize.new
        item.size = -1
        expect(item).to be_invalid
        expect(item.errors[:size]).to eq [ I18n.t("errors.messages.greater_than", count: 0) ]
      end

      it do
        item = SS::ImageResize.new
        item.size = 0
        expect(item).to be_invalid
        expect(item.errors[:size]).to eq [ I18n.t("errors.messages.greater_than", count: 0) ]
      end
    end

    describe "#quality" do
      it do
        item = SS::ImageResize.new
        expect(item).to be_invalid
        expect(item.errors[:quality]).to be_blank
      end

      it do
        item = SS::ImageResize.new
        item.quality = -1
        expect(item).to be_invalid
        expect(item.errors[:quality]).to eq [ I18n.t("errors.messages.greater_than_or_equal_to", count: 0) ]
      end

      it do
        item = SS::ImageResize.new
        item.quality = 101
        expect(item).to be_invalid
        expect(item.errors[:quality]).to eq [ I18n.t("errors.messages.less_than_or_equal_to", count: 100) ]
      end
    end
  end
end
