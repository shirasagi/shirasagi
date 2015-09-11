ClamScan.configure do |config|
  # provide default options to be passed to ClamScan::Client.scan
  # options passed directly to a call to ClamScan::Client.scan will override these
  # by merging the default options with the passed options
  config.default_scan_options       = {stdout: true} # default (request all output to be sent to STDOUT so it can be captured)

  # path to clamscan/clamdscan client
  # try `which clamdscan` or `which clamscan` in your shell to see where you should point this to
  # recommended to set to an absolute path to clamdscan
  config.client_location            = '/usr/bin/clamdscan' # default

  # if set to true, ClamScan will raise an exception
  # unless a scan is successful and no viruses were found
  config.raise_unless_safe          = false # default
end
