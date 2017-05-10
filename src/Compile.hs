{-# OPTIONS_GHC -Wall -fno-warn-unused-do-bind #-}
module Compile (compile) where

import Data.Text (Text)

import qualified AST.Expression.Canonical as Can
import qualified AST.Module as Module
import qualified AST.Module.Name as ModuleName
import qualified Canonicalize
import qualified Elm.Package as Package
import qualified Nitpick.PatternMatches as Nitpick
import qualified Nitpick.TopLevelTypes as Nitpick
import qualified Optimize
import qualified Parse.Parse as Parse (program)
import qualified Reporting.Error as Error
import qualified Reporting.Render.Type as RenderType
import qualified Reporting.Result as Result
import qualified Reporting.Warning as Warning
import qualified Type.Inference as TI


-- These imports are necessary for the ugly hack below
import qualified AST.Expression.General
import qualified AST.Expression.Valid
import qualified AST.Literal
import qualified AST.Pattern
import qualified AST.Variable
import qualified Data.List
import qualified Debug.Trace
import qualified Reporting.Annotation
import qualified Reporting.Region


-- COMPILE


type Result =
  Result.Result (Result.One RenderType.Localizer) Warning.Warning Error.Error


compile
    :: Package.Name
    -> [ModuleName.Canonical]
    -> Module.Interfaces
    -> Text
    -> Result Module.Optimized
compile packageName canonicalImports interfaces source =
  do
      -- Parse the source code
      originalValidModule <-
          Result.format Error.Syntax $
            {-# SCC elm_compiler_parse #-}
            Parse.program packageName source

      -- Ugly hack to make __moduleName__ available in scope
      validModule <-
        let
          namePath =
            case Module.name originalValidModule of
              ModuleName.Canonical packageName moduleName -> moduleName

          name =
            Data.List.intercalate "." namePath

          dummyPosition =
            Reporting.Region.Position 0 0

          region =
            Reporting.Region.Region dummyPosition dummyPosition

          pattern =
            Reporting.Annotation.A region (AST.Pattern.Var "__moduleName__")

          expression =
            Reporting.Annotation.A region (AST.Expression.General.Literal (AST.Literal.Str name))

          validDef =
            -- TODO add doc string
            AST.Expression.Valid.Def region pattern expression Nothing

          def =
            Reporting.Annotation.A (region, Nothing) validDef

          newModuleInfo =
            case Module.info originalValidModule of
              Module.Valid docs exports imports declarations effects ->
                case declarations of
                  D.Decls defs unions aliases infixes ->
                    Module.Valid
                        docs
                        exports
                        imports
                        (D.Decls (def : defs) unions aliases infixes)
                        effects

          extendedModule =
            Module.Module (Module.name originalValidModule) (Module.path originalValidModule) newModuleInfo
        in
          return extendedModule

      -- Canonicalize all variables, pinning down where they came from.
      canonicalModule <-
          {-# SCC elm_compiler_canonicalize #-}
          Canonicalize.module' canonicalImports interfaces validModule

      -- Run type inference on the program.
      types <-
          Result.from Error.Type $
            {-# SCC elm_compiler_types #-}
            TI.infer interfaces canonicalModule

      -- One last round of checks
      canonicalDefs <-
          Result.format Error.Type $
            {-# SCC elm_compiler_nitpick #-}
            Nitpick.topLevelTypes types $
              Can.toSortedDefs (Module.program (Module.info canonicalModule))

      tagDict <-
        Result.format Error.Pattern $
          {-# SCC elm_compiler_exhaustiveness #-}
          Nitpick.patternMatches interfaces canonicalModule

      -- Do some basic optimizations
      let optimisedDefs =
            {-# SCC elm_compiler_optimization #-}
            Optimize.optimize tagDict (Module.name canonicalModule) canonicalDefs

      -- Add the real list of types
      let info =
            (Module.info canonicalModule)
              { Module.types = types
              , Module.program = optimisedDefs
              }

      return $ canonicalModule { Module.info = info }
