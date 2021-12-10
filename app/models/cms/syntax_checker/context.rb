class Cms::SyntaxChecker::Context
  include ActiveModel::AttributeAssignment

  attr_accessor :cur_site, :cur_user, :contents, :errors
end
