require 'spec_helper'

describe SS, dbscope: :example do
  describe ".normalize_str" do
    let(:whitespace_characters) do
      %W[\u000A \u2000 \u2001 \u2002 \u2003 \u2004 \u2005 \u2006 \u2007 \u2008 \u2009 \u200A \u202F \u205F \u3000]
    end

    context "usual case" do
      let(:name) { "Music" }
      subject { SS.normalize_str(name) }

      it do
        expect(subject).to eq "Music"
      end
    end

    context "case1: with null byte" do
      let(:name) { "\t\n\v\f\r s \x00\ " }
      subject { SS.normalize_str(name) }

      it do
        expect(subject).to eq "s"
      end
    end

    context "case2: surrounded with Unicode whitespace characters" do
      let(:name) do
        # surround s with some Unicode whitespace characters.
        whitespace_characters.sample(3).join + "s" + whitespace_characters.sample(3).join
      end
      subject { SS.normalize_str(name) }

      it do
        expect(subject).to eq "s"
      end
    end

    context "case3: not invalid" do
      let(:name) { whitespace_characters.sample(7).join }
      subject { SS.normalize_str(name) }

      it do
        expect(subject).to eq ""
      end
    end
  end
end
