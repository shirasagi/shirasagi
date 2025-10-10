require 'spec_helper'

describe Cms::LoopSetting, dbscope: :example do
  describe ".search" do
    context "when nil is given" do
      subject { described_class.search(nil) }
      it { expect(subject.selector.to_h).to be_empty }
    end

    context "when name is given" do
      subject { described_class.search(name: "名前 なまえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名前/i, /なまえ/i))) }
    end

    context "when name includes regex meta characters" do
      subject { described_class.search(name: "名|前 な(*.?)まえ") }
      it { expect(subject.selector.to_h).to include("name" => include("$all" => include(/名\|前/i, /な\(\*\.\?\)まえ/i))) }
    end

    context "when keyword is given" do
      subject { described_class.search(keyword: "キーワード1 キーワード2") }
      it { expect(subject.selector.to_h).to include("$or" => include("name" => /キーワード1/i)) }
      it { expect(subject.selector.to_h).to include("$and" => include("$or" => include("name" => /キーワード2/i))) }
    end
  end

  describe "html_format" do
    let(:site) { cms_site }

    describe "default values" do
      subject { create(:cms_loop_setting, site: site) }

      it "has default html_format" do
        expect(subject.html_format).to eq "shirasagi"
      end
    end

    describe "html_format options" do
      it "returns correct options" do
        options = described_class.html_format_options
        expect(options).to include(%w[SHIRASAGI shirasagi])
        expect(options).to include(%w[Liquid liquid])
      end
    end

    describe "html_format behavior" do
      it "accepts shirasagi format" do
        loop_setting = build(:cms_loop_setting, site: site, html_format: "shirasagi")
        expect(loop_setting).to be_valid
        expect(loop_setting.html_format_shirasagi?).to be true
        expect(loop_setting.html_format_liquid?).to be false
      end

      it "accepts liquid format" do
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid")
        expect(loop_setting).to be_valid
        expect(loop_setting.html_format_shirasagi?).to be false
        expect(loop_setting.html_format_liquid?).to be true
      end

      it "treats blank format as shirasagi" do
        loop_setting = build(:cms_loop_setting, site: site, html_format: "")
        expect(loop_setting).to be_valid
        expect(loop_setting.html_format_shirasagi?).to be true
        expect(loop_setting.html_format_liquid?).to be false
      end

      it "treats nil format as shirasagi" do
        loop_setting = build(:cms_loop_setting, site: site, html_format: nil)
        expect(loop_setting).to be_valid
        expect(loop_setting.html_format_shirasagi?).to be true
        expect(loop_setting.html_format_liquid?).to be false
      end

      it "rejects invalid format" do
        loop_setting = build(:cms_loop_setting, site: site, html_format: "invalid")
        expect(loop_setting).not_to be_valid
        expect(loop_setting.errors[:html_format]).to include(I18n.t('errors.messages.inclusion'))
      end
    end

    describe "html field" do
      it "can set html for shirasagi format" do
        html_content = "<div class='item'>#{unique_id}</div>"
        loop_setting = create(:cms_loop_setting, site: site, html_format: "shirasagi", html: html_content)

        expect(loop_setting.html).to eq html_content
      end
    end
  end

  describe "HTML content validation" do
    let(:site) { cms_site }

    it "accepts valid HTML content" do
      valid_html = "<div class='test'>Content</div>"
      loop_setting = build(:cms_loop_setting, site: site, html: valid_html)
      expect(loop_setting).to be_valid
    end

    it "accepts empty HTML content" do
      loop_setting = build(:cms_loop_setting, site: site, html: "")
      expect(loop_setting).to be_valid
    end

    it "accepts nil HTML content" do
      loop_setting = build(:cms_loop_setting, site: site, html: nil)
      expect(loop_setting).to be_valid
    end
  end

  describe "state" do
    let(:site) { cms_site }

    it "defaults to public" do
      loop_setting = create(:cms_loop_setting, site: site, state: nil)
      expect(loop_setting.state).to eq "public"
    end

    it "accepts closed" do
      loop_setting = build(:cms_loop_setting, site: site, state: "closed")
      expect(loop_setting).to be_valid
    end

    it "rejects invalid values" do
      loop_setting = build(:cms_loop_setting, site: site, state: "invalid")
      expect(loop_setting).not_to be_valid
      expect(loop_setting.errors[:state]).to include(I18n.t('errors.messages.inclusion'))
    end
  end
end
