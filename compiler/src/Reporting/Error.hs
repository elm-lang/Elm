{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
module Reporting.Error
  ( Error(..)
  , toReports
  )
  where


import qualified Type.Error
import qualified Reporting.Error.Canonicalize as Canonicalize
import qualified Reporting.Error.Docs as Docs
import qualified Reporting.Error.Main as Main
import qualified Reporting.Error.Pattern as Pattern
import qualified Reporting.Error.Syntax as Syntax
import qualified Reporting.Error.Type as Type
import qualified Reporting.Render.Code as Code
import qualified Reporting.Report as Report



-- ALL POSSIBLE ERRORS


data Error
  = Syntax Syntax.Error
  | Canonicalize Canonicalize.Error
  | Type [Type.Error]
  | Main Main.Error
  | Pattern [Pattern.Error]
  | Docs Docs.Error



-- TO REPORT


toReports :: Code.Source -> Type.Error.Localizer -> Error -> [Report.Report]
toReports source localizer err =
  case err of
    Syntax syntaxError ->
        [Syntax.toReport source syntaxError]

    Canonicalize canonicalizeError ->
        [Canonicalize.toReport source canonicalizeError]

    Type typeErrors ->
        map (Type.toReport source localizer) typeErrors

    Main mainError ->
        [Main.toReport source mainError]

    Pattern patternErrors ->
        map (Pattern.toReport source) patternErrors

    Docs docsError ->
        [Docs.toReport source docsError]
