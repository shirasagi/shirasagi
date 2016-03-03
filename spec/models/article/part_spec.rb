require 'spec_helper'

describe Article::Part::Page, type: :model, dbscope: :example do
  let(:item) { create :article_part_page }
  it_behaves_like "cms_part#spec"
end
