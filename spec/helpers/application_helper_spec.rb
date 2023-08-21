require 'spec_helper'

describe ApplicationHelper, type: :helper do
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
end
