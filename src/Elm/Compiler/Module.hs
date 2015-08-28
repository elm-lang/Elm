module Elm.Compiler.Module
    ( Interface, Name(Name), name
    , CanonicalName(CanonicalName), canonicalName, canonPkg, canonModul
    , fromCanonicalName, canonFromPackage
    , nameToPath
    , nameToString, nameFromString
    , hyphenate, dehyphenate
    , defaultImports
    , interfacePorts
    , interfaceAliasedTypes
    )
  where

import Control.Monad (mzero)
import qualified Data.Aeson as Json
import Data.Binary
import qualified Data.Char as Char
import qualified Data.List as List
import qualified Data.Map as Map
import qualified Data.Text as Text
import System.FilePath ((</>))

import qualified AST.Module as Module
import qualified Elm.Compiler.Imports as Imports
import qualified Elm.Compiler.Type as Type
import qualified Elm.Compiler.Type.Extract as Extract
import qualified Elm.Package as Package


-- EXPOSED TYPES

type Interface = Module.Interface


newtype Name = Name [String]
    deriving (Eq, Ord)

data CanonicalName =
  CanonicalName
  { canonPkg :: Package.Name
  , canonVersion :: Package.Version
  , canonModul :: Name
  } deriving (Eq, Ord)


canonFromPackage :: Package.Package -> Name -> CanonicalName
canonFromPackage (pk, vr) nm =
  CanonicalName pk vr nm


fromCanonicalName :: CanonicalName -> Module.CanonicalName
fromCanonicalName (CanonicalName p _ (Name n)) =
  Module.CanonicalName p n


canonicalName :: Package.Name -> Package.Version -> Name -> CanonicalName
canonicalName = CanonicalName


name :: [String] -> Name
name = Name


defaultImports :: [Name]
defaultImports =
    map (Name . fst) Imports.defaults


-- POKING AROUND INTERFACES

interfacePorts :: Interface -> [String]
interfacePorts interface =
    Module.iPorts interface


interfaceAliasedTypes :: Interface -> Map.Map String Type.Type
interfaceAliasedTypes interface =
    Map.map Extract.toAliasedType (Module.iTypes interface)


-- STRING CONVERSIONS for NAMES

nameToPath :: Name -> FilePath
nameToPath (Name names) =
    List.foldl1 (</>) names


nameToString :: Name -> String
nameToString (Name names) =
    List.intercalate "." names


nameFromString :: String -> Maybe Name
nameFromString =
    fromString '.'


hyphenate :: Name -> String
hyphenate (Name names) =
    List.intercalate "-" names


dehyphenate :: String -> Maybe Name
dehyphenate =
    fromString '-'


fromString :: Char -> String -> Maybe Name
fromString sep raw =
    Name `fmap` mapM isLegit names
  where
    names =
        filter (/= [sep]) (List.groupBy (\a b -> a /= sep && b /= sep) raw)

    isLegit name =
        case name of
            [] -> Nothing
            char:rest ->
                if Char.isUpper char && all legitChar rest
                    then Just name
                    else Nothing

    legitChar char =
        Char.isAlphaNum char || char `elem` "_'"


-- JSON for NAME

instance Json.ToJSON Name where
    toJSON name =
        Json.toJSON (nameToString name)


instance Json.FromJSON Name where
    parseJSON (Json.String text) =
        let rawName = Text.unpack text in
        case nameFromString rawName of
            Nothing -> fail (rawName ++ " is not a valid module name")
            Just name -> return name

    parseJSON _ = mzero


-- BINARY for NAME

instance Binary Name where
  get =
    fmap Name get

  put (Name names) =
    put names
