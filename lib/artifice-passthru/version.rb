module Artifice
  module Passthru
    begin
      old, $VERBOSE = $VERBOSE, nil
      VERSION = '0.1.1'
    ensure
      $VERBOSE = old
    end
  end
end
