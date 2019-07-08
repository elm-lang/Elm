{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
module Generate.Html
  ( sandwich
  )
  where


import qualified Data.ByteString.Builder as B
import Data.Monoid ((<>))
import qualified Data.Name as Name
import Text.RawString.QQ (r)



-- SANDWICH


sandwich :: Name.Name -> B.Builder -> B.Builder
sandwich moduleName javascript =
  let name = Name.toBuilder moduleName in
  [r|<!DOCTYPE HTML>
<html>
<head>
  <meta charset="UTF-8">
  <title>|] <> name <> [r|</title>
  <style>body { padding: 0; margin: 0; }</style>
</head>

<body>

<pre id="elm">
This is a headless program, meaning there is nothing to show here.

I started the program anyway though!

You can access it as `app` in the developer console.
</pre>

<script>
|] <> javascript <> [r|

try {
  var app = Elm.|] <> name <> [r|.init({ node: document.getElementById("elm") });
} catch (e) {
  // display initialization errors (e.g. bad flags, infinite recursion)
  document.getElementById("elm").innerText = e;
  throw e;
}
</script>

</body>
</html>|]
