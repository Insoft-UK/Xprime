>`\bguard +(.*) +else\b`i IF NOT($1) THEN
>`\(([^?]+)\?(.+):(.+)\)` IFTE($1, $2, $3)
