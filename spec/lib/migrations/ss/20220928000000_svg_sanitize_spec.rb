require 'spec_helper'
require Rails.root.join("lib/migrations/ss/20220928000000_svg_sanitize.rb")

RSpec.describe SS::Migration20220928000000, dbscope: :example do
  let!(:file1) do
    tmp_ss_file(basename: "file1.svg").tap do |file|
      ::File.open(file.path, "w") do |f|
        f.write <<~SVG
          <?xml version="1.0" encoding="utf-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <text x="0" y="0">SHIRASAGI1</text>
            <text x="0" y="0" onclick="alert('xss')">SHIRASAGI2</text>
            <a xlink:href="javascript:alert('xss')"><text x="0" y="0">SHIRASAGI3</text></a>
            <a xlink:href="https://very.very.danger.com/"><text x="0" y="0">SHIRASAGI4</text></a>
            <a xlink:href="/path/to/page.html"><text x="0" y="0">SHIRASAGI5</text></a>
            <script>alert("xss")</script>
          </svg>
        SVG
      end
      file.set(content_type: SS::File::SVG_MIME_TYPE, size: ::File.size(file.path))
    end
  end

  before do
    described_class.new.change
  end

  it do
    content = ::File.read(file1.path)
    expect(content).not_to include("onclick")
    expect(content).not_to include("javascript:")
    expect(content).not_to include("very.very.danger.com")
    expect(content).not_to include("<script")
    expect(content).to include("/path/to/page.html")

    SS::File.find(file1.id).tap do |fix_file|
      expect(fix_file.size).to eq ::File.size(fix_file.path)
      expect(fix_file.size).to be < file1.size
    end
  end
end
