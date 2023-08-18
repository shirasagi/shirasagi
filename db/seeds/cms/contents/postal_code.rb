puts "# postal_code"
Sys::PostalCode::OfficialCsvImportJob.import_from_zip("postal_code/13tokyo.zip")
