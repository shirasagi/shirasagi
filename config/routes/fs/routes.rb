SS::Application.routes.draw do

  Fs::Initializer

  namespace "fs" do
    get "*id_path/_/:filename" => "files#index", id_path: %r{(\d\/)*\d}, filename: %r{[^\/]+}, as: :file, format: false
    get "*id_path/_/thumb/:filename" => "files#thumb", id_path: %r{(\d\/)*\d}, filename: %r{[^\/]+}, as: :thumb, format: false
    get "*id_path/_/thumb/:size/:filename" => "files#thumb", id_path: %r{(\d\/)*\d}, size: %r{[^\/]+},
      filename: %r{[^\/]+}, format: false

    # @deprecated
    get ":id/:filename" => "files#index", filename: %r{[^\/]+}, as: :file_old
    # @deprecated
    get ":id/thumb/:filename" => "files#thumb", filename: %r{[^\/]+}, as: :thumb_old
    # @deprecated
    get ":id/thumb/:size/:filename" => "files#thumb", filename: %r{[^\/]+}, size: %r{[^\/]+}
  end
end
