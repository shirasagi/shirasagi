require 'spec_helper'

RSpec.describe GravatarHelper, type: :helper do
  let(:email) { "user@example.jp" }
  let(:md5sum) { "12b75d826c225ac1e313d05d44cce941" }

  describe "assertion" do
    it { expect(Digest::MD5.hexdigest(email)).to eq md5sum }
  end

  describe ".gravatar_image_url" do
    it "returns Gravatar's image URL" do
      expect(helper.gravatar_image_url(email, 100)).to eq "https://gravatar.com/avatar/#{md5sum}?s=100"
    end

    describe "default \"size\"" do
      it("is 150") { expect(helper.gravatar_image_url(email)).to eq  "https://gravatar.com/avatar/#{md5sum}?s=150" }
    end

    describe "with a default image URL" do
      default = "http%3A%2F%2Fexample.com%2Fimages%2Favatar.jpg"
      default_before_escape = "http://example.com/images/avatar.jpg"

      it { expect(CGI.escape(default_before_escape)).to eq default }
      it { expect(helper.gravatar_image_url(email, 150, default: default_before_escape)).to eq "https://gravatar.com/avatar/#{md5sum}?s=150&d=#{default}" }
    end
  end

  describe ".gravatar_image_tag" do
    it "returns an img element which has \"image_url\" as a \"src\"" do
      expect(helper.gravatar_image_tag(email, 100)).to eq "<img src=\"https://gravatar.com/avatar/#{md5sum}?s=100\" />"
    end

    it "returns an img element which has some attributes" do
      expect(helper.gravatar_image_tag(email, 100, alt: "alt", title: "title")).to eq(
          "<img alt=\"alt\" title=\"title\" src=\"https://gravatar.com/avatar/#{md5sum}?s=100\" />"
        )
    end
  end
end
