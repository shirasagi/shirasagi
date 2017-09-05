SS::Application.routes.draw do
  Gws::File::Initializer

  gws "file" do
    resource :setting, only: [:show, :edit, :update]
  end
end
