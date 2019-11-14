# Attempts to tidy those ridiculously long ARNs into something more concise
def arnchomp:
  if type == "string" then
    . | split(":") | last | split("/") | last
  else
    .
  end;
