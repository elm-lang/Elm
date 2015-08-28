module AST.Module
    ( Interfaces, CanonicalInterfaces
    , Types, Aliases, ADTs
    , AdtInfo, CanonicalAdt
    , SourceModule, ValidModule, CanonicalModule, Optimized
    , Module(..), Body(..)
    , Header(..)
    , Name, nameToString, nameIsNative
    , CanonicalName(..), canonPkg, canonModul
    , Interface(..), toInterface
    , UserImport, DefaultImport, ImportMethod(..)
    ) where

import Control.Applicative ((<$>),(<*>))
import Data.Binary
import qualified Data.List as List
import qualified Data.Map as Map

import qualified AST.Declaration as Decl
import qualified AST.Expression.Canonical as Canonical
import qualified AST.Expression.Optimized as Optimized
import qualified AST.Type as Type
import qualified AST.Variable as Var
import qualified Docs.AST as Docs
import qualified Elm.Package as Package
import qualified Elm.Compiler.Version as Compiler
import qualified Reporting.Annotation as A


-- HELPFUL TYPE ALIASES

type Interfaces = Map.Map Name Interface
type CanonicalInterfaces = Map.Map CanonicalName Interface

type Types   = Map.Map String Type.Canonical
type Aliases = Map.Map String ([String], Type.Canonical)
type ADTs    = Map.Map String (AdtInfo String)

type AdtInfo v = ( [String], [(v, [Type.Canonical])] )
type CanonicalAdt = (Var.Canonical, AdtInfo Var.Canonical)


-- MODULES

type SourceModule =
    Module
      String
      [UserImport]
      (Var.Listing (A.Located Var.Value))
      [Decl.SourceDecl]


type ValidModule =
    Module
      String
      ([DefaultImport], [UserImport])
      (Var.Listing (A.Located Var.Value))
      [Decl.ValidDecl]


type CanonicalModule =
    Module Docs.Centralized [Name] [Var.Value] (Body Canonical.Expr)


type Optimized =
    Module Docs.Centralized [Name] [Var.Value] (Body Optimized.Expr)


data Module docs imports exports body = Module
    { names   :: Name
    , path    :: FilePath
    , docs    :: A.Located (Maybe docs)
    , exports :: exports
    , imports :: imports
    , body    :: body
    }


data Body expr = Body
    { program   :: expr
    , types     :: Types
    , fixities  :: [(Decl.Assoc, Int, String)]
    , aliases   :: Aliases
    , datatypes :: ADTs
    , ports     :: [String]
    }


-- HEADERS

{-| Basic info needed to identify modules and determine dependencies. -}
data Header imports = Header
    { _names :: Name
    , _docs :: A.Located (Maybe String)
    , _exports :: Var.Listing (A.Located Var.Value)
    , _imports :: imports
    }


type Name = [String] -- must be non-empty


data CanonicalName =
  CanonicalName
  { canonPkg :: Package.Name
  , canonModul :: Name
  }


nameToString :: Name -> String
nameToString =
  List.intercalate "."


nameIsNative :: Name -> Bool
nameIsNative name =
  case name of
    "Native" : _ -> True
    _ -> False


-- IMPORTs

type UserImport = A.Located (Name, ImportMethod)


type DefaultImport = (Name, ImportMethod)


data ImportMethod = ImportMethod
    { alias :: Maybe String
    , exposedVars :: !(Var.Listing Var.Value)
    }


-- INTERFACES

{-| Key facts about a module, used when reading info from .elmi files. -}
data Interface = Interface
    { iVersion  :: String
    , iExports  :: [Var.Value]
    , iTypes    :: Types
    , iImports  :: [Name]
    , iAdts     :: ADTs
    , iAliases  :: Aliases
    , iFixities :: [(Decl.Assoc, Int, String)]
    , iPorts    :: [String]
    , iPackage  :: Package.Name 
    }


toInterface :: Package.Name -> CanonicalModule -> Interface
toInterface pkgName modul =
    let body' = body modul in
    Interface
    { iVersion  = Package.versionToString Compiler.version
    , iExports  = exports modul
    , iTypes    = types body'
    , iImports  = imports modul
    , iAdts     = datatypes body'
    , iAliases  = aliases body'
    , iFixities = fixities body'
    , iPorts    = ports body'
    , iPackage  = pkgName
    }


instance Binary Interface where
  get = Interface <$> get <*> get <*> get <*> get <*> get <*> get <*> get <*> get <*> get
  put modul = do
      put (iVersion modul)
      put (iExports modul)
      put (iTypes modul)
      put (iImports modul)
      put (iAdts modul)
      put (iAliases modul)
      put (iFixities modul)
      put (iPorts modul)
      put (iPackage modul)
