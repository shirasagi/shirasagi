require 'spec_helper'
require Rails.root.join('lib/migrations/ss/20170523000000_fix_scss_compass')

RSpec.describe SS::Migration20170523000000, dbscope: :example do
  let(:text1) do
    str = []
    str << '@import "compass/css3";'
    str << '@import "compass/typography/text/ellipsis";'
    str << 'aaa { color: red; }'
    str.join("\n")
  end

  let(:text2) do
    str = []
    str << '@import "compass-mixins/lib/compass";'
    str << '//@import "compass/css3";'
    str << '//@import "compass/typography/text/ellipsis";'
    str << 'aaa { color: red; }'
    str.join("\n")
  end

  subject(:item) { described_class.new }

  it do
    expect(item.change_text(text1)).to eq text2
  end
end
