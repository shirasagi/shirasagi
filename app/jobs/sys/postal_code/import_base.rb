class Sys::PostalCode::ImportBase < SS::ApplicationJob
  include SS::ZipFileImport
end
