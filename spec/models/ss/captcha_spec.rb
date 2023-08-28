require 'spec_helper'

describe SS::Captcha, type: :model, dbscope: :example do
  describe ".generate_captcha" do
    shared_examples "generated captcha is" do
      it do
        expect(captcha).to be_present
        expect(captcha).to be_persisted
        expect(captcha.captcha_text).to be_present
        expect(captcha.captcha_error).to be_blank
        expect(captcha.out_captcha_image_base64).to be_present

        binary = Base64.strict_decode64(captcha.out_captcha_image_base64)
        expect(binary).to be_present

        image = MiniMagick::Image.read(StringIO.new(binary))
        expect(image.mime_type).to eq "image/jpeg"
        expect(image.width).to eq 100
        expect(image.height).to eq 30
      end
    end

    context "with ImageMagick6" do
      let(:captcha) do
        MiniMagick.with_cli(:imagemagick) do
          SS::Captcha.generate_captcha
        end
      end

      include_context "generated captcha is"
    end

    context "with GraphicsMagick" do
      let(:captcha) do
        MiniMagick.with_cli(:graphicsmagick) do
          SS::Captcha.generate_captcha
        end
      end

      include_context "generated captcha is"
    end
  end
end
