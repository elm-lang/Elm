{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
module Canonicalize.Effects (canonicalize, toValues, checkPortType) where

import qualified Data.Foldable as F
import Data.Text (Text)

import qualified AST.Effects as Effects
import qualified AST.Type as T
import qualified AST.Variable as Var
import qualified Reporting.Annotation as A
import qualified Reporting.Error.Canonicalize as Error
import qualified Reporting.Region as R
import qualified Reporting.Result as Result
import qualified Canonicalize.Environment as Env
import qualified Canonicalize.Type as Canonicalize
import Canonicalize.Variable (Result)



-- TO EXPORT VALUES


toValues :: Effects.Raw -> [Var.Value]
toValues effects =
  case effects of
    Effects.None ->
      []

    Effects.Manager _ _ ->
      []

    Effects.Port ports ->
      map (Var.Value . Effects._rawName . A.drop) ports



-- CANONICALIZE


canonicalize :: Env.Env -> Effects.Raw -> Result Effects.Canonical
canonicalize env effects =
  case effects of
    Effects.None ->
      Result.ok Effects.None

    Effects.Manager _ info ->
      Result.ok (Effects.Manager (Env.getPackage env) info)

    Effects.Port rawPorts ->
      Effects.Port <$> traverse (canonicalizeRawPort env) rawPorts


canonicalizeRawPort
  :: Env.Env
  -> A.Commented Effects.PortRaw
  -> Result (A.Commented Effects.PortCanonical)
canonicalizeRawPort env (A.A ann (Effects.PortRaw name rawType)) =
  do  tipe <- Canonicalize.tipe env rawType
      kind <- figureOutKind (fst ann) name tipe
      Result.ok (A.A ann (Effects.PortCanonical name kind tipe))


figureOutKind :: R.Region -> Text -> T.Canonical -> Result Effects.Kind
figureOutKind region name rootType =
  case T.deepDealias rootType of

    -- outgoing port
    -- port actions: Json.Encode.Value -> Cmd msg
    T.Lambda outgoingType (T.App (T.Type effect) [T.Var _])
      | effect == Var.cmd ->
          pure (Effects.Outgoing outgoingType)
            <* checkPortType (makeError region name) outgoingType

    -- incoming port
    -- port viewModel : (Model -> msg) -> Sub msg
    T.Lambda (T.Lambda incomingType (T.Var msg1)) (T.App (T.Type effect) [T.Var msg2])
      | effect == Var.sub && msg1 == msg2 ->
          pure (Effects.Incoming incomingType)
            <* checkPortType (makeError region name) incomingType

    -- task port
    -- port getUsername : Int -> Task Error String
    T.Lambda outgoingType (T.App (T.Type task) [incomingErrorType, incomingSuccessType])
      | True ->
      -- | Var.isTask task -> -- TODO verify that it's a Task
          pure (Effects.Twoway outgoingType incomingErrorType incomingSuccessType)
            <* checkPortType (makeError region name) outgoingType
            <* checkPortType (makeError region name) incomingErrorType
            <* checkPortType (makeError region name) incomingSuccessType

    _ ->
      Result.throw region (Error.BadPort name rootType)


makeError :: R.Region -> Text -> T.Canonical -> Maybe Text -> A.Located Error.Error
makeError region name tipe maybeMessage =
  A.A region (Error.port name tipe maybeMessage)



-- CHECK INCOMING AND OUTGOING TYPES


checkPortType
  :: (Monoid i)
  => (T.Canonical -> Maybe Text -> A.Located e)
  -> T.Canonical
  -> Result.Result i w e ()
checkPortType mkError tipe =
  let
    check =
      checkPortType mkError

    throw maybeMsg =
      Result.throwMany [mkError tipe maybeMsg]
  in
    case tipe of
      T.Aliased _ args aliasedType ->
        check (T.dealias args aliasedType)

      T.Type name ->
        if Var.isJson name || Var.isPrimitive name || Var.isTuple name then
          return ()

        else
          throw Nothing

      T.App name [] ->
          check name

      T.App (T.Type name) [arg]
          | Var.isMaybe name -> check arg
          | Var.isArray name -> check arg
          | Var.isList  name -> check arg

      T.App (T.Type name) args
          | Var.isTuple name ->
              F.traverse_ check args

      T.App _ _ ->
          throw Nothing

      T.Var _ ->
          throw (Just "free type variable")

      T.Lambda _ _ ->
          throw (Just "function")

      T.Record _ (Just _) ->
          throw (Just "extended record")

      T.Record fields Nothing ->
          F.traverse_ (\(k,v) -> (,) k <$> check v) fields
