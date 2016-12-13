class Cms::PostalCode::ImportBase < Cms::ApplicationJob
  include SS::ZipFileImport
end
