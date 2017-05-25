require 'spec_helper'
require Rails.root.join('lib/migrations/ss/20170411153100_fix_cms_pages_contains_urls.rb')

RSpec.describe SS::Migration20170411153100, dbscope: :example do
  before do
    create_once :cms_body_layout
    create_once :article_page, name: "cms_page1",
      html: '<a href="/docs/">/docs/</a><a href="http://www.ss-proj.org/">http://www.ss-proj.org/</a>'
    create_once :cms_page, name: "cms_page2",
      html: '<img src="/fs/1/1/1/_/example.jpg">'
    create_once :article_page, name: "cms_page3",
      html: '<div>html</div>'
    create_once :article_page, name: "cms_page4",
       html: '<a href="/docs/">/docs/</a><a href="http://www.ss-proj.org/">http://www.ss-proj.org/</a>',
       body_parts: [ '<a href="/kurashi/"></a>', '<a href="/kosodate/"></a>' ],
       body_layout_id: Cms::BodyLayout.first.id
  end

  it do
    described_class.new.change

    cms_page1 = Cms::Page.where(name: "cms_page1").first
    cms_page2 = Cms::Page.where(name: "cms_page2").first
    cms_page3 = Cms::Page.where(name: "cms_page3").first
    cms_page4 = Cms::Page.where(name: "cms_page4").first

    expect(cms_page1.contains_urls).to match_array %w(/docs/ http://www.ss-proj.org/)
    expect(cms_page2.contains_urls).to match_array %w(/fs/1/1/1/_/example.jpg)
    expect(cms_page3.contains_urls).to match_array []
    expect(cms_page4.contains_urls).to match_array %w(/kurashi/ /kosodate/)
  end
end
