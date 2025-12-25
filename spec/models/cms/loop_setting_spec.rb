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

    context "when html_format is given" do
      subject { described_class.search(html_format: "liquid") }
      it { expect(subject.selector.to_h).to include("html_format" => "liquid") }
    end

    context "when loop_html_setting_type is given" do
      subject { described_class.search(loop_html_setting_type: "snippet") }
      it { expect(subject.selector.to_h).to include("loop_html_setting_type" => "snippet") }
    end
  end

  describe "html_format" do
    let(:site) { cms_site }

    describe "default values" do
      subject { create(:cms_loop_setting, site: site) }

      it "has default html_format" do
        expect(subject.html_format).to eq "shirasagi"
      end

      it "has default loop_html_setting_type" do
        expect(subject.loop_html_setting_type).to eq "template"
      end
    end

    describe "options helpers" do
      let(:loop_setting) { described_class.new }

      it "returns state options for label helper" do
        options = loop_setting.state_options
        expect(options).to include([I18n.t('ss.options.state.public'), 'public'])
        expect(options).to include([I18n.t('ss.options.state.closed'), 'closed'])
      end

      it "returns html_format options for label helper" do
        options = loop_setting.html_format_options
        expect(options).to include([I18n.t('cms.options.loop_format.shirasagi'), 'shirasagi'])
        expect(options).to include([I18n.t('cms.options.loop_format.liquid'), 'liquid'])
      end

      it "returns loop_html_setting_type options for label helper" do
        options = loop_setting.loop_html_setting_type_options
        expect(options).to include([I18n.t('cms.options.loop_html_setting_type.template'), 'template'])
        expect(options).to include([I18n.t('cms.options.loop_html_setting_type.snippet'), 'snippet'])
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
    end

    describe "html field" do
      it "can set html for shirasagi format" do
        html_content = "<div class='item'>#{unique_id}</div>"
        loop_setting = create(:cms_loop_setting, site: site, html_format: "shirasagi", html: html_content)

        expect(loop_setting.html).to eq html_content
      end

      it "can set html for liquid format" do
        liquid_content = "{% for item in items %}<div class='item'>{{ item.name }}</div>{% endfor %}"
        loop_setting = create(:cms_loop_setting, site: site, html_format: "liquid", html: liquid_content)

        expect(loop_setting.html).to eq liquid_content
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

  describe "Liquid format validation" do
    let(:site) { cms_site }

    context "when html_format is liquid" do
      it "accepts valid liquid template" do
        valid_liquid = "{% for item in items %}<div>{{ item.name }}</div>{% endfor %}"
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid", html: valid_liquid)
        expect(loop_setting).to be_valid
      end

      it "accepts valid liquid syntax with conditions" do
        valid_liquid = "{% if items.size > 0 %}{% for item in items %}<div>{{ item.name }}</div>{% endfor %}{% endif %}"
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid", html: valid_liquid)
        expect(loop_setting).to be_valid
      end

      it "accepts plain HTML without liquid tags" do
        plain_html = "<div class='layout'><p>Content</p></div>"
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid", html: plain_html)
        expect(loop_setting).to be_valid
      end

      it "accepts empty HTML content" do
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid", html: "")
        expect(loop_setting).to be_valid
      end

      it "accepts nil HTML content" do
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid", html: nil)
        expect(loop_setting).to be_valid
      end

      it "rejects invalid liquid template" do
        invalid_liquid = "{% for item in items %}<div>{{ item.name }}</div>{% endfor"
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid", html: invalid_liquid)
        expect(loop_setting).not_to be_valid
        expect(loop_setting.errors[:html]).to be_present
      end

      it "rejects malformed liquid syntax" do
        invalid_liquid = "{% if items.size > 0 %}{% for item in items %}<div>{{ item.name }}</div>{% endfor %}{% endif"
        loop_setting = build(:cms_loop_setting, site: site, html_format: "liquid", html: invalid_liquid)
        expect(loop_setting).not_to be_valid
        expect(loop_setting.errors[:html]).to be_present
      end
    end

    context "when html_format is shirasagi" do
      it "does not validate liquid format" do
        # shirasagi形式では、Liquidバリデーションが適用されないため、無効なLiquidテンプレートでも受け入れられる
        invalid_liquid = "{% for item in items %}<div>{{ item.name }}</div>{% endfor"
        loop_setting = build(:cms_loop_setting, site: site, html_format: "shirasagi", html: invalid_liquid)
        expect(loop_setting).to be_valid
      end

      it "accepts valid HTML content" do
        valid_html = "<div class='test'>Content</div>"
        loop_setting = build(:cms_loop_setting, site: site, html_format: "shirasagi", html: valid_html)
        expect(loop_setting).to be_valid
      end
    end
  end

  describe "state" do
    let(:site) { cms_site }

    it "defaults to public" do
      loop_setting = Cms::LoopSetting.create!(
        cur_site: site,
        name: "loop-setting-#{unique_id}"
      )
      expect(loop_setting.state).to eq "public"
      expect(loop_setting.loop_html_setting_type).to eq "template"
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

  describe "loop_html_setting_type" do
    let(:site) { cms_site }

    it "defaults to template" do
      loop_setting = Cms::LoopSetting.create!(
        cur_site: site,
        name: "loop-setting-#{unique_id}"
      )
      expect(loop_setting.loop_html_setting_type).to eq "template"
    end

    it "accepts snippet" do
      loop_setting = build(:cms_loop_setting, site: site, loop_html_setting_type: "snippet")
      expect(loop_setting).to be_valid
      expect(loop_setting.loop_html_setting_type_snippet?).to be true
      expect(loop_setting.loop_html_setting_type_template?).to be false
    end

    it "accepts template" do
      loop_setting = build(:cms_loop_setting, site: site, loop_html_setting_type: "template")
      expect(loop_setting).to be_valid
      expect(loop_setting.loop_html_setting_type_template?).to be true
      expect(loop_setting.loop_html_setting_type_snippet?).to be false
    end

    it "rejects invalid values" do
      loop_setting = build(:cms_loop_setting, site: site, loop_html_setting_type: "invalid")
      expect(loop_setting).not_to be_valid
      expect(loop_setting.errors[:loop_html_setting_type]).to include(I18n.t('errors.messages.inclusion'))
    end
  end
end
