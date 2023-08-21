module SS::ImplicitRenderFilter
  extend ActiveSupport::Concern

  # override default_render
  # 4-2 stable : https://github.com/rails/rails/blob/4-2-stable/actionpack/lib/action_controller/metal/implicit_render.rb
  # 5-1 stable : https://github.com/rails/rails/blob/5-1-stable/actionpack/lib/action_controller/metal/implicit_render.rb
  def default_render(*args)
    render(*args)
  end
end
