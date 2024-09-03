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
        expect(image.type).to eq "JPEG"
        expect(image.width).to eq 100
        expect(image.height).to eq 30
      end
    end

    context "with ImageMagick6/7" do
      let(:captcha) do
        SS::Captcha.generate_captcha
      end

      include_context "generated captcha is"
    end

    context "with GraphicsMagick" do
      # As of MiniMagick 5+, GraphicsMagick isn't officially supported. However, we can work with it
      let(:captcha) do
        save_cli_prefix = nil
        MiniMagick.configure do |config|
          save_cli_prefix = config.cli_prefix
          config.cli_prefix = "gm"
        end

        SS::Captcha.generate_captcha
      ensure
        MiniMagick.configure do |config|
          config.cli_prefix = save_cli_prefix
        end
      end

      include_context "generated captcha is"
    end
  end
end
