#frozen_string_literal: true

class Gws::Tabular::View::DefaultView
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :cur_space, :cur_form

  alias site cur_site
  alias site= cur_site=

  alias space cur_space
  alias space= cur_space=

  alias form cur_form
  alias form= cur_form=

  def view_paths
    []
  end

  def order_hash
    {}
  end

  def index_template_path
    "gws/tabular/files/default_view/index"
  end

  def owned?(*_args, **_options)
    true
  end

  def to_key
    [ to_param ]
  end

  def to_param
    "-"
  end

  def authoring_allowed?(_premission)
    true
  end

  def authoring_any_allowed?(*_premissions)
    true
  end
end
