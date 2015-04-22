SS::Application.routes.draw do

  Fs::Initializer

  namespace "fs" do
    get ":id/:filename" => "files#index", filename: %r([^\/]+), as: :file
    get ":id/thumb/:filename" => "files#thumb", filename: %r([^\/]+), as: :thumb
  end
end
