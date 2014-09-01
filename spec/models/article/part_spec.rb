require 'spec_helper'

describe Article::Part::Page do
  subject(:model) { Article::Part::Page }
  subject(:factory) { :article_part_page }

  it_behaves_like "mongoid#save"
  it_behaves_like "mongoid#find"
end
