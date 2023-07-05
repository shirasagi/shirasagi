require 'spec_helper'

describe ApplicationHelper, type: :helper, dbscope: :example do
  describe ".mail_to_entity" do
    context "when only email address is given" do
      subject { helper.mail_to_entity("test@example.jp") }
      it { is_expected.to eq '<a href="mailto:test&#64;example&#46;jp">test&#64;example&#46;jp</a>' }
    end

    context "when email address and name is given" do
      subject { helper.mail_to_entity("test@example.jp", "テスト") }
      it { is_expected.to eq '<a href="mailto:test&#64;example&#46;jp">テスト</a>' }
    end
  end

  describe ".br" do
    context "when nil is given" do
      subject { helper.br(nil) }
      it { is_expected.to eq '' }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when blank string is given" do
      subject { helper.br('') }
      it { is_expected.to eq '' }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when multiline separated by '\\n' is given" do
      subject { helper.br("<a>\n'b'") }
      it { is_expected.to eq "&lt;a&gt;<br />&#39;b&#39;" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when multiline separated by '\\r' is given" do
      subject { helper.br("<a>\r'b'") }
      it { is_expected.to eq "&lt;a&gt;<br />&#39;b&#39;" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when multiline separated by '\\r\\n' is given" do
      subject { helper.br("<a>\r\n'b'") }
      it { is_expected.to eq "&lt;a&gt;<br />&#39;b&#39;" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when string only contains \n" do
      subject { helper.br("\n\n\n") }
      it { is_expected.to eq "<br /><br /><br />" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when array is given" do
      subject { helper.br([ "<a>", '', "'b'" ]) }
      it { is_expected.to eq "&lt;a&gt;<br /><br />&#39;b&#39;" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when multiple params are given" do
      subject { helper.br("<a>", '', "'b'") }
      it { is_expected.to eq "&lt;a&gt;<br /><br />&#39;b&#39;" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when option `html_escape: false` is given" do
      subject { helper.br("<a>\r\n'b'", html_escape: false) }
      it { is_expected.to eq "<a><br />'b'" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end

    context "when non-string objects are given" do
      subject { helper.br(1, { a: 1 }, URI.parse("http://www.yahoo.co.jp/"), html_escape: false) }
      it { is_expected.to eq "1<br />{:a=>1}<br />http://www.yahoo.co.jp/" }
      it { is_expected.to be_a ActiveSupport::SafeBuffer }
    end
  end

  describe ".ss_application_name" do
    context "when @cur_site isn't given" do
      subject { helper.ss_application_name }
      it { is_expected.to eq SS.config.ss.application_name }
    end

    context "when @cur_site is given" do
      context "when logo_application_name isn't given" do
        subject { helper.ss_application_name }
        before { @cur_site = gws_site }
        it { is_expected.to eq SS.config.ss.application_name }
      end

      context "when logo_application_name is blank" do
        subject { helper.ss_application_name }
        before do
          @cur_site = gws_site
          @cur_site.logo_application_name = ""
        end
        it { is_expected.to eq SS.config.ss.application_name }
      end

      context "when logo_application_name is presented" do
        let(:logo_application_name) { unique_id }
        subject { helper.ss_application_name }
        before do
          @cur_site = gws_site
          @cur_site.logo_application_name = logo_application_name
        end
        it { is_expected.to eq logo_application_name }
      end
    end
  end

  describe ".render_application_logo" do
    context "when @cur_site isn't given" do
      subject { helper.render_application_logo }
      it { is_expected.to eq SS.config.ss.application_logo_html }
    end

    context "when @cur_site is given" do
      context "when both logo_application_name and logo_application_image aren't given" do
        subject { helper.render_application_logo }
        before { @cur_site = gws_site }
        it { is_expected.to eq SS.config.ss.application_logo_html }
      end

      context "when only logo_application_name is given and it is blank" do
        let(:site) do
          site = gws_site
          site.logo_application_name = ""
          site
        end
        subject { helper.render_application_logo(site) }
        it { is_expected.to eq SS.config.ss.application_logo_html }
      end

      context "when only logo_application_name is given and it is present" do
        let(:logo_application_name) { unique_id }
        let(:site) do
          site = gws_site
          site.logo_application_name = logo_application_name
          site
        end
        subject { helper.render_application_logo(site) }
        let(:img_part) { "" }
        let(:span_part) { %(<span class="ss-logo-application-name">#{logo_application_name}</span>) }
        it { is_expected.to eq %(<div class="ss-logo-wrap">#{img_part}#{span_part}</div>) }
      end

      context "when only logo_application_image is given" do
        let(:logo_application_image) do
          tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: "#{unique_id}.png")
        end
        let(:site) do
          site = gws_site
          site.logo_application_image = logo_application_image
          site
        end
        subject { helper.render_application_logo(site) }
        let(:img_part) { %(<img alt="#{SS.config.ss.application_name}" src="#{logo_application_image.url}" />) }
        let(:span_part) { "" }
        it { is_expected.to eq %(<div class="ss-logo-wrap">#{img_part}#{span_part}</div>) }
      end

      context "when both logo_application_name and logo_application_image are given" do
        let(:logo_application_name) { unique_id }
        let(:logo_application_image) do
          tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: "#{unique_id}.png")
        end
        let(:site) do
          site = gws_site
          site.logo_application_name = logo_application_name
          site.logo_application_image = logo_application_image
          site
        end
        subject { helper.render_application_logo(site) }
        let(:img_part) { %(<img alt="#{logo_application_name}" src="#{logo_application_image.url}" />) }
        let(:span_part) { %(<span class="ss-logo-application-name">#{logo_application_name}</span>) }
        it { is_expected.to eq %(<div class="ss-logo-wrap">#{img_part}#{span_part}</div>) }
      end
    end
  end
end
