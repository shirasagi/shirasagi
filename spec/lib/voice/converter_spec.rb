require 'spec_helper'

describe Voice::Converter do
  subject(:site) { cms_site }

  describe "#convert", open_jtalk: true do
    it 'creates wav from html' do
      html = <<-EOF
              <html>
                <body>
                  <article class="body">
                    <p>株式会社</p>
                  </article>
                </body>
              </html>
      EOF
      tmp = Tempfile::new(['talk', '.wav'], '/tmp')

      Voice::Converter.convert(site.id, html, tmp.path)
      expect(tmp.stat.size).to satisfy { |v| v > 1000 }
    end

    it 'creates wav from "/index.html"' do
      source_file = Rails.root.join('spec', 'fixtures', 'voice', 'test-001.html')
      expect(::File.exists?(source_file)).to be_true

      html = File.read source_file
      tmp = Tempfile::new(['talk', '.wav'], '/tmp')

      Voice::Converter.convert(site.id, html, tmp.path)
      expect(tmp.stat.size).to satisfy { |v| v > 20_000 }
    end
  end
end
