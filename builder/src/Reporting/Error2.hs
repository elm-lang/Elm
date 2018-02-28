{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
module Reporting.Error2
  ( Error(..)
  , toString
  , toStderr
  )
  where


import qualified Text.PrettyPrint.ANSI.Leijen as P

import qualified Elm.Compiler as Compiler
import qualified Elm.Compiler.Module as Module
import qualified Elm.Package as Pkg
import qualified Elm.Utils as Utils
import qualified Reporting.Error.Assets as Asset
import qualified Reporting.Error.Bump as Bump
import qualified Reporting.Error.Compile as Compile
import qualified Reporting.Error.Crawl as Crawl
import qualified Reporting.Error.Deps as Deps
import qualified Reporting.Error.Diff as Diff
import qualified Reporting.Error.Help as Help
import qualified Reporting.Error.Http as Http
import qualified Reporting.Error.Publish as Publish



-- ALL POSSIBLE ERRORS


data Error
  = NoElmJson
  | Assets Asset.Error
  | Bump Bump.Error
  | Compile Compile.Error [Compile.Error]
  | Crawl Crawl.Error
  | Cycle [Module.Raw] -- TODO write docs to help with this scenario
  | Deps Deps.Error
  | Diff Diff.Error
  | Publish Publish.Error
  | BadHttp String Http.Error

  -- install
  | NoSolution [Pkg.Name]
  | CannotMakeNothing



-- RENDERERS


toString :: Error -> String
toString err =
  Help.toString (Help.reportToDoc (toReport err))


toStderr :: Error -> IO ()
toStderr err =
  Help.toStderr (Help.reportToDoc (toReport err))


toReport :: Error -> Help.Report
toReport err =
  case err of
    NoElmJson ->
      Help.report "WELCOME" Nothing
        "It looks like you are trying to start a new Elm project. Very exciting! :D"
        [ P.fillSep
            ["I","very","highly","recommend","working","through"
            ,P.green "<https://guide.elm-lang.org>","which","will","teach","you","the"
            ,"basics","of","Elm,","including","how","to","start","new","projects."
            ]
        , P.fillSep
            ["For","folks","who","have","already","built","stuff","with","Elm,","the"
            ,"problem","is","just","that","there","is","no",P.dullyellow "elm.json","yet."
            ,"If","you","want","to","work","from","an","example,","check","out","the"
            ,"one","at","<https://github.com/evancz/elm-todomvc/blob/master/elm.json>"
            ]
        , Help.reflow
            "Whatever your scenario, I hope you have a lovely time using Elm!"
        ]

    Assets assetError ->
      Asset.toReport assetError

    Bump bumpError ->
      Bump.toReport bumpError

    Compile e es ->
      Help.compilerReport $ Compile.toDoc e es

    Crawl crawlError ->
      Crawl.toReport crawlError

    Cycle names ->
      Help.report "IMPORT CYCLE" Nothing
        "Your module imports form a cycle:"
        [ P.indent 4 (Utils.drawCycle names)
        , Help.reflow $
            "Learn more about why this is disallowed and how to break cycles here:"
            ++ Help.hintLink "import-cycles"
        ]

    Deps depsError ->
      Deps.toReport depsError

    Diff commandsError ->
      Diff.toReport commandsError

    Publish publishError ->
      Publish.toReport publishError

    BadHttp url httpError ->
      Http.toReport url httpError

    NoSolution badPackages ->
      case badPackages of
        [] ->
          Help.report "UNSOLVABLE DEPENDENCIES" (Just "elm.json")
            "This usually happens if you try to modify dependency constraints by\
            \ hand. I recommend deleting any dependency you added recently (or all\
            \ of them if things are bad) and then adding them again with:"
            [ P.indent 4 $ P.green "elm install"
            , Help.reflow $
                "And do not be afaid to ask for help on Slack if you get stuck!"
            ]

        _:_ ->
          Help.report "OLD DEPENDENCIES" (Just "elm.json")
            ( "You are using Elm " ++ Pkg.versionToString Compiler.version
              ++ ", but the following packages have not been updated for this version yet:"
            )
            [ P.vcat $ map (P.red . P.text . Pkg.toString) badPackages
            , Help.note
                "Please be kind to the relevant package authors! Having friendly interactions\
                \ with users is great motivation, and conversely, getting berated by strangers\
                \ on the internet sucks your soul dry. Furthermore, package authors are humans\
                \ with families, friends, jobs, vacations, responsibilities, goals, etc. They\
                \ face obstacles outside of their technical work you will never know about,\
                \ so please assume the best and try to be patient and supportive!"
            ]

    CannotMakeNothing ->
      Help.report "NO INPUT" Nothing
        "What should I make though? I need more information, like:"
        [ P.vcat
            [ P.indent 4 $ P.green "elm make MyThing.elm"
            , P.indent 4 $ P.green "elm make This.elm That.elm"
            ]
        , Help.reflow
            "However many files you give, I will create one JS file out of them."
        ]
