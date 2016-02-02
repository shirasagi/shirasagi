require 'spec_helper'

describe Mobile::Converter do
  describe "#remove_other_namespace_tags!" do
    def do_remove_other_namespace_tags!(text)
      val = described_class.new(text)
      val.send(:remove_other_namespace_tags!)
      val
    end

    context "when normal html is given" do
      subject { do_remove_other_namespace_tags!("<p>テスト</p>") }
      it { is_expected.to eq "<p>テスト</p>" }
    end

    context "when prefixed tag is given" do
      subject { do_remove_other_namespace_tags!("<prefix:tag>テスト</prefix:tag>") }
      it { is_expected.to eq "テスト" }
    end

    context "when tel number is given" do
      subject { do_remove_other_namespace_tags!("<p>09:00～17:00</p>") }
      it { is_expected.to eq "<p>09:00～17:00</p>" }
    end
  end

  describe "#s_to_attr" do
    def do_s_to_attr(str)
      val = described_class.new.s_to_attr(str)
    end

    context "when div tag string is given" do
      subject { do_s_to_attr(%( div class="cls" )) }
      it { is_expected.to eq({ "class"=>"cls" }) }
    end

    context "when img tag string is given" do
      subject { do_s_to_attr(%(img alt="image" src="/path")) }
      it { is_expected.to eq({ "alt"=>"image", "src"=>"/path" }) }
    end

    context "when img tag string (include empty attribute) is given" do
      subject { do_s_to_attr(%(img alt="" src="/path")) }
      it { is_expected.to eq({ "alt"=>"", "src"=>"/path" }) }
    end
  end

  describe "#convert!" do
    def do_convert!(text)
      val = described_class.new(text)
      val.convert!
      val
    end

    context "when normal html is given" do
      subject { do_convert!("<p>テスト</p>") }
      it { is_expected.to eq "<p>テスト</p>" }
    end

    context "when prefixed tag is given" do
      subject { do_convert!("<prefix:tag>テスト</prefix:tag>") }
      it { is_expected.to eq "テスト" }
    end

    context "when tel number is given" do
      subject { do_convert!("<p>09:00～17:00</p>") }
      it { is_expected.to eq "<p>09:00～17:00</p>" }
    end

    context "when upper case tag is given" do
      subject { do_convert!("<P>テスト</P>") }
      it { is_expected.to eq "<p>テスト</p>" }
    end

    context "when comment is given" do
      subject { do_convert!("<!-- コメント -->") }
      it { is_expected.to eq "" }
    end

    context "when multi-lined comment is given" do
      subject do
        do_convert!(%(<!--
            コメント
          -->))
      end
      it { is_expected.to eq "" }
    end

    context "when cdata is given" do
      subject do
        do_convert!(%(<![CDATA[
            cdata section &&& >><<
          ]]>))
      end
      it { is_expected.to eq "" }
    end

    context "when audio tag is given" do
      subject { do_convert!("<audio src=\"sample/sample.ogg\" controls>") }
      it { is_expected.to eq "" }
    end

    context "when multi-source audio tag is given" do
      subject do
        do_convert!(%(<audio controls>
            <source src="horse.ogg" type="audio/ogg">
            <source src="horse.mp3" type="audio/mpeg">
            Your browser does not support the audio tag.
          </audio>))
      end
      it { is_expected.to eq "" }
    end

    context "when thead tag is given" do
      subject { do_convert!("<thead><tr><th>header1</th><th>header2</th></tr></thead>") }
      it { is_expected.to eq "<tr><th>header1</th><th>header2</th></tr>" }
    end

    context "when article tag is given" do
      subject { do_convert!("<article><h1>header1</h1></article>") }
      it { is_expected.to eq "<div><h1>header1</h1></div>" }
    end

    context "when label tag is given" do
      subject { do_convert!("<label>label</label>") }
      it { is_expected.to eq "<span>label</span>" }
    end

    context "when img tag is given" do
      context "when jpg is given" do
        context "when alt attribute is given" do
          subject { do_convert!("<img src=\"sample.jpg\" alt=\"sample\">") }
          it { is_expected.to eq "sample <a href=\"sample.jpg\" class=\"tag-img\" title=\"sample\">[画像]</a>" }
        end

        context "when title attribute is given" do
          subject { do_convert!("<img src=\"sample.jpg\" title=\"sample\">") }
          it { is_expected.to eq "sample <a href=\"sample.jpg\" class=\"tag-img\" title=\"sample\">[画像]</a>" }
        end

        context "when no additoinal attributes is given" do
          subject { do_convert!("<img src=\"sample.jpg\">") }
          it { is_expected.to eq "sample.jpg <a href=\"sample.jpg\" class=\"tag-img\" title=\"sample.jpg\">[画像]</a>" }
        end
      end

      context "when png is given" do
        context "when alt attribute is given" do
          subject { do_convert!("<img src=\"sample.png\" alt=\"sample\">") }
          it { is_expected.to eq "<img src=\"sample.png\" alt=\"sample\">" }
        end

        context "when title attribute is given" do
          subject { do_convert!("<img src=\"sample.png\" title=\"sample\">") }
          it { is_expected.to eq "<img src=\"sample.png\" title=\"sample\">" }
        end

        context "when no additoinal attributes is given" do
          subject { do_convert!("<img src=\"sample.png\">") }
          it { is_expected.to eq "<img src=\"sample.png\">" }
        end
      end
    end
  end
end
