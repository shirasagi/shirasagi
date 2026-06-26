require 'spec_helper'

describe Kana::Converter, dbscope: :example, mecab: true do
  describe ".mpad" do
    it do
      expect(described_class.send(:mpad, "<body>")).to eq "<body>"
      expect(described_class.send(:mpad, "あ")).to eq " " * 3
      # emoji "corn"
      expect(described_class.send(:mpad, "\xf0\x9f\x8c\xbd")).to eq " " * 4
      # 点のある塚（宝塚や平塚の「塚」の本当の文字）: JIS X 0213 に定義がある
      expect(described_class.send(:mpad, "\xe5\xa1\x9a\xf3\xa0\x84\x85")).to eq " " * 7
    end
  end
end
