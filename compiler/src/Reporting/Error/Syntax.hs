{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
module Reporting.Error.Syntax
  ( Error(..)
  --
  , Module(..)
  , Exposing(..)
  --
  , Decl(..)
  , DeclType(..)
  , TypeAlias(..)
  , CustomType(..)
  , DeclDef(..)
  , Port(..)
  --
  , Expr(..)
  , Record(..)
  , Tuple(..)
  , List(..)
  , Func(..)
  , Case(..)
  , If(..)
  , Let(..)
  , Def(..)
  , Destruct(..)
  --
  , Pattern(..)
  , PRecord(..)
  , PTuple(..)
  , PList(..)
  --
  , Type(..)
  , TRecord(..)
  , TTuple(..)
  --
  , Char(..)
  , String(..)
  , Escape(..)
  , Number(..)
  --
  , Space(..)
  , Operator(..)
  , toReport
  )
  where


import Prelude hiding (Char, String)
import qualified Data.Char as Char
import qualified Data.Name as Name
import Data.Word (Word16)
--import Numeric (showHex)

import qualified Elm.ModuleName as ModuleName
import Parse.Primitives (Row, Col)
--import qualified Parse.Primitives as P
import qualified Reporting.Annotation as A
--import qualified Reporting.Doc as D
import qualified Reporting.Report as Report
import qualified Reporting.Render.Code as Code



-- ALL SYNTAX ERRORS


data Error
  = ModuleNameUnspecified ModuleName.Raw
  | ModuleNameMismatch ModuleName.Raw ModuleName.Raw
  | UnexpectedPort A.Region
  | NoPorts A.Region
  | ParseError Module



-- MODULE


data Module
  = ModuleSpace Space Row Col
  | ModuleEndOfFile Row Col
  | Module Row Col
  | ModuleName Row Col
  | ModuleExposing Row Col
  | ModuleExposingList Exposing Row Col
  --
  | ModulePortModule Row Col
  | ModuleEffect Row Col
  --
  | ModuleIndentStart Row Col
  | ModuleIndentName Row Col
  | ModuleIndentExposing Row Col
  | ModuleIndentExposingList Row Col
  | ModuleIndentPortModule Row Col
  --
  | FreshLineModuleStart Row Col
  | FreshLineAfterModuleLine Row Col
  | FreshLineAfterDocComment Row Col
  --
  | ImportStart Row Col
  | ImportName Row Col
  | ImportAs Row Col
  | ImportAlias Row Col
  | ImportExposing Row Col
  | ImportExposingList Exposing Row Col
  | ImportEnd Row Col -- different based on col=1 or if greater
  --
  | ImportIndentName Row Col
  | ImportIndentAs Row Col
  | ImportIndentAlias Row Col
  | ImportIndentExposing Row Col
  | ImportIndentExposingList Row Col
  --
  | Infix Row Col
  --
  | Declarations Decl Row Col


data Exposing
  = ExposingSpace Space Row Col
  | ExposingStart Row Col
  | ExposingValue Row Col
  | ExposingOperator Row Col
  | ExposingOperatorReserved Operator Row Col
  | ExposingOperatorRightParen Row Col
  | ExposingEnd Row Col
  --
  | ExposingTypePrivacy Row Col
  | ExposingTypePrivacyDots Row Col
  | ExposingTypePrivacyEnd Row Col
  --
  | ExposingIndentEnd Row Col
  | ExposingIndentValue Row Col
  | ExposingIndentValueEnd Row Col
  | ExposingIndentTypePrivacy Row Col
  | ExposingIndentTypePrivacyDots Row Col
  | ExposingIndentTypePrivacyEnd Row Col



-- DECLARATIONS


data Decl
  = DeclStart Row Col
  | DeclSpace Space Row Col
  --
  | Port Port Row Col
  | DeclType DeclType Row Col
  | DeclDef Name.Name DeclDef Row Col
  --
  | DeclFreshLineStart Row Col
  | DeclFreshLineAfterDocComment Row Col


data DeclDef
  = DeclDefSpace Space Row Col
  | DeclDefEquals Row Col
  | DeclDefType Type Row Col
  | DeclDefArg Pattern Row Col
  | DeclDefBody Expr Row Col
  | DeclDefNameRepeat Name.Name Row Col
  | DeclDefNameMatch Name.Name Name.Name Row Col
  --
  | DeclDefIndentType Row Col
  | DeclDefIndentEquals Row Col
  | DeclDefIndentBody Row Col
  --
  | DeclDefFreshLineAfterType Row Col


data Port
  = PortSpace Space Row Col
  | PortName Row Col
  | PortColon Row Col
  | PortType Type Row Col
  | PortIndentName Row Col
  | PortIndentColon Row Col
  | PortIndentType Row Col



-- TYPE DECLARATIONS


data DeclType
  = DT_Space Space Row Col
  | DT_Name Row Col
  | DT_Alias TypeAlias Row Col
  | DT_Union CustomType Row Col
  --
  | DT_IndentName Row Col


data TypeAlias
  = AliasSpace Space Row Col
  | AliasName Row Col
  | AliasEquals Row Col
  | AliasBody Type Row Col
  --
  | AliasIndentEquals Row Col
  | AliasIndentBody Row Col


data CustomType
  = CT_Space Space Row Col
  | CT_Name Row Col
  | CT_Equals Row Col
  | CT_Bar Row Col
  | CT_Variant Row Col
  | CT_VariantArg Type Row Col
  --
  | CT_IndentEquals Row Col
  | CT_IndentBar Row Col
  | CT_IndentAfterBar Row Col
  | CT_IndentAfterEquals Row Col



-- EXPRESSIONS


data Expr
  = Let Let Row Col
  | Case Case Row Col
  | If If Row Col
  | List List Row Col
  | Record Record Row Col
  | Update Expr Row Col
  | Tuple Tuple Row Col
  | Func Func Row Col
  --
  | Dot Row Col
  | Access Row Col
  | OperatorRHS Row Col
  | OperatorRight Row Col
  | OperatorReserved Operator Row Col
  --
  | Start Row Col
  | Char Char Row Col
  | String String Row Col
  | Number Number Row Col
  | Space Space Row Col
  | EndlessShader Row Col
  | ShaderProblem [Char.Char] Row Col
  | IndentOperatorRight Row Col
  | IndentMoreExpr Row Col


data Record
  = RecordOpen Row Col
  | RecordEnd Row Col
  | RecordField Row Col
  | RecordEquals Row Col
  | RecordExpr Expr Row Col
  | RecordSpace Space Row Col
  --
  | RecordIndentOpen Row Col
  | RecordIndentEnd Row Col
  | RecordIndentField Row Col
  | RecordIndentEquals Row Col
  | RecordIndentExpr Row Col


data Tuple
  = TupleOpen Row Col
  | TupleExpr Expr Row Col
  | TupleSpace Space Row Col
  | TupleEnd Row Col
  | TupleOperatorClose Row Col
  | TupleOperatorReserved Operator Row Col
  --
  | TupleIndentExpr Row Col
  | TupleIndentEnd Row Col


data List
  = ListSpace Space Row Col
  | ListOpen Row Col
  | ListExpr Expr Row Col
  | ListEnd Row Col
  --
  | ListIndentOpen Row Col
  | ListIndentEnd Row Col
  | ListIndentExpr Row Col


data Func
  = FuncSpace Space Row Col
  | FuncArg Pattern Row Col
  | FuncBody Expr Row Col
  | FuncArrow Row Col
  --
  | FuncIndentArg Row Col
  | FuncIndentArrow Row Col
  | FuncIndentBody Row Col


data Case
  = CaseSpace Space Row Col
  | CaseOf Row Col
  | CasePattern Pattern Row Col
  | CaseArrow Row Col
  | CaseExpr Expr Row Col
  | CaseBranch Expr Row Col
  --
  | CaseIndentOf Row Col
  | CaseIndentExpr Row Col
  | CaseIndentPattern Row Col
  | CaseIndentArrow Row Col
  | CaseIndentBranch Row Col
  | CasePatternAlignment Word16 Row Col


data If
  = IfSpace Space Row Col
  | IfThen Row Col
  | IfElse Row Col
  | IfElseBranchStart Row Col
  --
  | IfCondition Expr Row Col
  | IfThenBranch Expr Row Col
  | IfElseBranch Expr Row Col
  --
  | IfIndentCondition Row Col
  | IfIndentThen Row Col
  | IfIndentThenBranch Row Col
  | IfIndentElseBranch Row Col
  | IfIndentElse Row Col


data Let
  = LetSpace Space Row Col
  | LetIn Row Col
  | LetDefAlignment Word16 Row Col
  | LetDefName Row Col
  | LetDef Name.Name Def Row Col
  | LetDestruct Destruct Row Col
  | LetBody Expr Row Col
  | LetIndentDef Row Col
  | LetIndentIn Row Col
  | LetIndentBody Row Col


data Def
  = DefSpace Space Row Col
  | DefType Type Row Col
  | DefNameRepeat Name.Name Row Col
  | DefNameMatch Name.Name Name.Name Row Col
  | DefArg Pattern Row Col
  | DefEquals Row Col
  | DefBody Expr Row Col
  | DefIndentEquals Row Col
  | DefIndentType Row Col
  | DefIndentBody Row Col
  | DefAlignment Word16 Row Col


data Destruct
  = DestructSpace Space Row Col
  | DestructPattern Pattern Row Col
  | DestructEquals Row Col
  | DestructBody Expr Row Col
  | DestructIndentEquals Row Col
  | DestructIndentBody Row Col



-- PATTERNS


data Pattern
  = PRecord PRecord Row Col
  | PTuple PTuple Row Col
  | PList PList Row Col
  --
  | PStart Row Col
  | PChar Char Row Col
  | PString String Row Col
  | PNumber Number Row Col
  | PFloat Int Row Col
  | PAlias Row Col
  | PWildcardNotVar Int Row Col
  | PSpace Space Row Col
  --
  | PIndentStart Row Col
  | PIndentAlias Row Col


data PRecord
  = PRecordOpen Row Col
  | PRecordEnd Row Col
  | PRecordField Row Col
  | PRecordSpace Space Row Col
  --
  | PRecordIndentOpen Row Col
  | PRecordIndentEnd Row Col
  | PRecordIndentField Row Col


data PTuple
  = PTupleOpen Row Col
  | PTupleEnd Row Col
  | PTupleExpr Pattern Row Col
  | PTupleSpace Space Row Col
  --
  | PTupleIndentOpen Row Col
  | PTupleIndentEnd Row Col
  | PTupleIndentExpr Row Col


data PList
  = PListOpen Row Col
  | PListEnd Row Col
  | PListExpr Pattern Row Col
  | PListSpace Space Row Col
  --
  | PListIndentOpen Row Col
  | PListIndentEnd Row Col
  | PListIndentExpr Row Col



-- TYPES


data Type
  = TRecord TRecord Row Col
  | TTuple TTuple Row Col
  | TVariant Row Col
  | TArrow Row Col
  --
  | TStart Row Col
  | TSpace Space Row Col
  --
  | TIndentStart Row Col


data TRecord
  = TRecordOpen Row Col
  | TRecordEnd Row Col
  --
  | TRecordField Row Col
  | TRecordColon Row Col
  | TRecordType Type Row Col
  --
  | TRecordSpace Space Row Col
  --
  | TRecordIndentOpen Row Col
  | TRecordIndentField Row Col
  | TRecordIndentColon Row Col
  | TRecordIndentType Row Col
  | TRecordIndentEnd Row Col


data TTuple
  = TTupleOpen Row Col
  | TTupleEnd Row Col
  | TTupleType Type Row Col
  | TTupleSpace Space Row Col
  --
  | TTupleIndentOpen Row Col
  | TTupleIndentType Row Col
  | TTupleIndentEnd Row Col



-- LITERALS


data Char
  = CharEndless
  | CharEscape Escape
  | CharNotString Int


data String
  = StringEndless_Single
  | StringEndless_Multi
  | StringEscape Escape


data Escape
  = EscapeUnknown Word16 Word16
  | BadUnicodeFormat Word16 Word16
  | BadUnicodeCode Word16 Word16
  | BadUnicodeLength Word16 Word16 Int Int


data Number
  = NumberEnd
  | NumberDot Int
  | NumberHexDigit
  | NumberNoLeadingZero



-- MISC


data Space
  = HasTab
  | EndlessMultiComment
  | UnexpectedDocComment


data Operator
  = OpDot
  | OpPipe
  | OpArrow
  | OpEquals
  | OpHasType



-- TO REPORT


toReport :: Code.Source -> Error -> Report.Report
toReport source err =
  error "TODO" source err
{-
  case err of
    CommentOnNothing region ->
      Report.Report "STRAY COMMENT" region [] $
        Report.toCodeSnippet source region Nothing
          (
            "This documentation comment is not followed by anything."
          ,
            D.reflow $
              "All documentation comments need to be right above the declaration they\
              \ describe. Maybe some code got deleted or commented out by accident? Or\
              \ maybe this comment is here by accident?"
          )

    UnexpectedPort region ->
      Report.Report "UNEXPECTED PORTS" region [] $
        Report.toCodeSnippet source region Nothing
          (
            D.reflow $
              "You are declaring ports in a normal module."
          ,
            D.stack
              [ D.fillSep
                  ["Switch","this","to","say",D.green "port module","instead,"
                  ,"marking","that","this","module","contains","port","declarations."
                  ]
              , D.link "Note"
                  "Ports are not a traditional FFI for calling JS functions directly. They need a different mindset! Read"
                  "ports"
                  "to learn the syntax and how to use it effectively."
              ]
          )

    NoPorts region ->
      Report.Report "NO PORTS" region [] $
        Report.toCodeSnippet source region Nothing
          (
            D.reflow $
              "This module does not declare any ports, but it says it will:"
          ,
            D.fillSep
              ["Switch","this","to",D.green "module"
              ,"and","you","should","be","all","set!"
              ]
          )

    ParseError row col context expectation ->
      let
        pos = A.Position row col
        region = A.Region pos pos
      in
      case expectation of
        TODO ->
          error "TODO no parse error yet"

        XXX ->
          error "TODO no parse error yet"

        -- Parse.Utils

        HasTab ->
          Report.Report "NO TABS" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I ran into a tab, but tabs are not allowed in Elm files."
              ,
                D.reflow $
                  "Replace the tab with spaces."
              )

        DocComment ->
          Report.Report "EXPECTING DOC COMMENT" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting a doc comment here:"
              ,
                D.reflowLink
                  "Check out" "TODO" "for examples of doc comments."
              )

        MultiCommentEnd startRow startCol ->
          let
            startRegion =
              A.Region
                (A.Position startRow startCol)
                (A.Position startRow (startCol + 3))
          in
          Report.Report "ENDLESS COMMENT" startRegion [] $
            Report.toCodeSnippet source startRegion Nothing
              (
                D.reflow $
                  "I cannot find the end of this multi-line comment:"
              ,
                D.stack -- "{-"
                  [ D.reflow "Add a -} somewhere after this to end the comment."
                  , D.toSimpleHint
                      "Multi-line comments can be nested in Elm, so {- {- -} -} is a comment\
                      \ that happens to contain another comment. Like parentheses and curly braces,\
                      \ the start and end markers must always be balanced. Maybe that is the problem?"
                  ]
              )

        -- Parse.Number

        Number_Start ->
          Report.Report "EXPECTING NUMBER" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting to see a number here:"
              ,
                D.stack
                  [ D.reflow $
                      "I recognize numbers in the following formats:"
                  , D.indent 4 $ D.vcat [ "42", "3.14", "6.022e23", "0x002B" ]
                  , D.reflow $
                      "So is there a way to write it like one of those?"
                  ]
              )

        Number_End ->
          Report.Report "WEIRD NUMBER" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I thought I was reading a number, but I ran into some weird stuff here:"
              ,
                D.stack
                  [ D.reflow $
                      "I recognize numbers in the following formats:"
                  , D.indent 4 $ D.vcat [ "42", "3.14", "6.022e23", "0x002B" ]
                  , D.reflow $
                      "So is there a way to write it like one of those?"
                  ]
              )

        Number_Dot int ->
          Report.Report "WEIRD NUMBER" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "Numbers cannot end with a dot like this:"
              ,
                D.fillSep
                  ["Switching","to",D.green (D.fromChars (show int))
                  ,"or",D.green (D.fromChars (show int ++ ".0"))
                  ,"will","work","though!"
                  ]
              )

        Number_HexDigit ->
          Report.Report "WEIRD HEXIDECIMAL" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I thought I was reading a hexidecimal number until I got here:"
              ,
                D.stack
                  [ D.reflow $
                      "Valid hexidecimal digits include 0123456789abcdefABCDEF, so I can\
                      \ only recognize things like this:"
                  , D.indent 4 $ D.vcat [ "0x2B", "0x002B", "0x00ffb3" ]
                  ]
              )

        Number_NoLeadingZero ->
          Report.Report "LEADING ZEROS" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I do not accept numbers with leading zeros:"
              ,
                D.stack
                  [ D.reflow $
                      "Just delete the leading zeros and it should work!"
                  , D.toSimpleNote $
                      "Some languages let you to specify octal numbers by adding a leading zero.\
                      \ So in C, writing 0111 is the same as writing 73. Some people are used to\
                      \ that, but others probably want it to equal 111. Either path is going to\
                      \ surprise people from certain backgrounds, so Elm tries to avoid this whole\
                      \ situation."
                  ]
              )

        Precedence ->
          Report.Report "EXPECTING PRECEDENCE" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting the precedence here:"
              ,
                D.reflow $
                  "I need a single digit between 0 and 9 inclusive."
              )

        -- Parse.Utf8

        CharStart ->
          Report.Report "EXPECTING A CHARACTER" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting a character here:"
              ,
                D.stack
                  [ D.reflow $
                      "Characters start and end with single quotes, like this:"
                  , D.indent 4 $ D.vcat $
                      [ "'a'"
                      , "'b'"
                      , "'ø'"
                      , "'\\n'"
                      , "'\\u{00F8}'"
                      ]
                  , D.reflow $
                      "That last style lets you encode characters by their unicode\
                      \ code point, so 'a' is equivalent to '\\u{0061}', 'ø' is\
                      \ equivalent to '\\u{00F8}', and so on for all code points."
                  ]
              )

        CharEnd ->
          Report.Report "MISSING SINGLE QUOTE" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I thought I was parsing a character, but I got to the end of\
                  \ the line without seeing the closing single quote:"
              ,
                D.stack
                  [ D.reflow $
                      "Characters start and end with single quotes, like this:"
                  , D.indent 4 $ D.vcat $
                      [ "'a'"
                      , "'b'"
                      , "'ø'"
                      , "'\\n'"
                      , "'\\u{00F8}'"
                      ]
                  , D.reflow $
                      "That last style lets you encode characters by their unicode\
                      \ code point, so 'a' is equivalent to '\\u{0061}', 'ø' is\
                      \ equivalent to '\\u{00F8}', and so on for all code points."
                  ]
              )

        CharNotString startRow startCol ->
          let
            stringRegion =
              A.Region (A.Position startRow startCol) pos
          in
          Report.Report "NEEDS DOUBLE QUOTES" stringRegion [] $
            Report.toCodeSnippet source stringRegion Nothing
              (
                "The following string uses single quotes:"
              ,
                D.stack
                  [ "Please switch to double quotes instead:"
                  , D.indent 4 $
                      D.dullyellow "'this'" <> " => " <> D.green "\"this\""
                  , D.toSimpleNote $
                      "Elm uses double quotes for strings like \"hello\", whereas it uses single\
                      \ quotes for individual characters like 'a' and 'ø'. This distinction helps with\
                      \ code like (String.any (\\c -> c == 'X') \"90210\") where you are inspecting\
                      \ individual characters."
                  ]
              )

        StringStart ->
          Report.Report "EXPECTING A STRING" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting a string here:"
              ,
                D.fillSep
                  ["Something","like"
                  ,D.green "\"this\""
                  ,"or"
                  ,D.green "\"that\""
                  ,"with","double","quotes."
                  ]
              )

        StringEnd_Single ->
          Report.Report "ENDLESS STRING" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I got to the end of the line without seeing the closing double quote:"
              ,
                D.stack
                  [ D.fillSep $
                      ["Strings","look","like",D.green "\"this\"","with","double"
                      ,"quotes","on","each","end.","Is","the","closing","double"
                      ,"quote","missing","in","your","code?"
                      ]
                  , D.link "Note" "Read" "TODO" "if you want a string that spans multiple lines."
                  ]
              )

        StringEnd_Multi startRow startCol ->
          let
            startRegion =
              A.Region
                (A.Position startRow startCol)
                (A.Position startRow (startCol + 3))
          in
          Report.Report "ENDLESS STRING" startRegion [] $
            Report.toCodeSnippet source startRegion Nothing
              (
                D.reflow $
                  "I cannot find the end of this multi-line string:"
              ,
                D.stack
                  [ D.reflow "Add a \"\"\" somewhere after this to end the string."
                  , D.link "Hint" "Read" "TODO" "for more information on strings and multi-line strings."
                  ]
              )

        EscapeUnknown startCol endCol ->
          let
            escapeRegion =
              A.Region (A.Position row startCol) (A.Position row endCol)
          in
          Report.Report "UNKNOWN ESCAPE" escapeRegion [] $
            Report.toCodeSnippet source escapeRegion Nothing
              (
                D.reflow $
                  "Backslashes always start escaped characters, but I do not recognize this one:"
              ,
                D.stack
                  [ D.reflow $
                      "Valid escape characters include:"
                  , D.indent 4 $ D.vcat $
                        [ "\\n"
                        , "\\r"
                        , "\\t"
                        , "\\\""
                        , "\\\'"
                        , "\\\\"
                        , "\\u{03BB}"
                        ]
                  , D.reflow $
                      "The last one lets encode ANY character by its Unicode code\
                      \ point, so use that for anything outside the ordinary six."
                  ]
              )

        BadUnicodeFormat startCol endCol ->
          let
            escapeRegion =
              A.Region (A.Position row startCol) (A.Position row endCol)
          in
          Report.Report "BAD UNICODE ESCAPE" escapeRegion [] $
            Report.toCodeSnippet source escapeRegion Nothing
              (
                D.reflow $
                  "I ran into an invalid Unicode escape:"
              ,
                D.stack
                  [ D.reflow $
                      "Here are some examples of valid Unicode escapes:"
                  , D.green $ D.indent 4 $ D.vcat $
                      [ "\\u{0041}"
                      , "\\u{03BB}"
                      , "\\u{6728}"
                      , "\\u{1F60A}"
                      ]
                  , D.reflow $
                      "Notice that the code point is always surrounded by curly\
                      \ braces. They are required!"
                  ]
                )

        BadUnicodeCode startCol endCol ->
          let
            escapeRegion =
              A.Region (A.Position row startCol) (A.Position row endCol)
          in
          Report.Report "BAD UNICODE ESCAPE" escapeRegion [] $
            Report.toCodeSnippet source escapeRegion Nothing
              (
                D.reflow $
                  "This is not a valid code point:"
              ,
                D.reflow $
                  "The valid code points are between 0 and 10FFFF inclusive."
              )

        BadUnicodeLength startCol endCol numDigits badCode ->
          let
            escapeRegion =
              A.Region (A.Position row startCol) (A.Position row endCol)
          in
          Report.Report "BAD UNICODE ESCAPE" escapeRegion [] $
            Report.toCodeSnippet source escapeRegion Nothing $
              if numDigits < 4 then
                (
                  D.reflow $
                    "Every code point needs at least four digits:"
                ,
                  let
                    goodCode = replicate (4 - numDigits) '0' ++ showHex badCode ""
                    escape = "\\u{" <> D.fromChars goodCode <> "}"
                  in
                  D.fillSep ["Try",D.green escape,"instead?"]
                )

              else
                (
                  D.reflow $
                    "This code point has too many digits:"
                ,
                  D.fillSep $
                    ["Valid","code","points","are","between"
                    ,D.green "\\u{0000}","and",D.green "\\u{10FFFF}" <> ","
                    ,"so","try","trimming","any","leading","zeros","until"
                    ,"you","have","between","four","and","six","digits."
                    ]
                )

        -- Parse.Shader

        ShaderStart ->
          Report.Report "EXPECTING A SHADER" region [] $
            Report.toCodeSnippet source region Nothing $
              (
                D.reflow $
                  "I was expecting a GLSL shader block here:"
              ,
                D.reflow $
                  "These blocks start with [glsl| and end with |] and should be\
                  \ filled with GLSL code."
              )

        ShaderEnd startCol endCol ->
          let
            shaderRegion =
              A.Region (A.Position row startCol) (A.Position row endCol)
          in
          Report.Report "ENDLESS SHADER" shaderRegion [] $
            Report.toCodeSnippet source shaderRegion Nothing
              (
                D.reflow "I cannot find the end of this shader:"
              ,
                D.reflow "Add a |] somewhere after this to end the shader."
              )

        ShaderProblem problem ->
          Report.Report "SHADER PROBLEM" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I ran into a problem while parsing this GLSL block."
              ,
                D.fromChars problem
              )

        Operator ->
          Report.Report "EXPECTING AN OPERATOR" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting an operator here:"
              ,
                D.stack
                  [ D.reflow "Some of the most common operators are:"
                  , D.indent 4 $ D.vcat ["+","-","*","&&","||"]
                  , D.reflow "Something like that!"
                  ]
              )

        ReservedOperator op ->
          error "TODO ReservedOperator" op

        Wildcard ->
          Report.Report "EXPECTING A WILDCARD" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting a _ here:"
              ,
                D.reflow $
                  "An underscore indicates that “I do not care about this value” and is\
                  \ called a wildcard pattern because it will match with any type of values."
              )

        WildcardNotVar startCol endCol ->
          let
            badRegion =
              A.Region (A.Position row startCol) (A.Position row endCol)
          in
          Report.Report "INVALID PATTERN" badRegion [] $
            Report.toCodeSnippet source badRegion Nothing
              (
                D.reflow $
                  "I was expecting to see an underscore without any additional characters:"
              ,
                D.reflow $
                  "There are two options. Either (1) remove the extra characters and ignore the\
                  \ value or (2) remove the starting underscore to give the value a normal name."
              )

        -- Parse.Pattern

        Pattern ->
          error "TODO" context
{-
          case context of
            P.Frame r c
            P.NoContext ->
-}

        FloatInPattern ->
          Report.Report "INVALID PATTERN" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I cannot pattern match with floating point numbers:"
              ,
                D.reflow $
                  "Equality on floats can be unreliable, so you usually want to check that they\
                  \ are nearby with some sort of (abs (actual - expected) < 0.001) check."
              )

        FieldNamePattern ->
          Report.Report "EXPECTING A FIELD NAME" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was expecting a field name here:"
              ,
                D.fillSep $
                  ["A","name","like",D.dullyellow "id" <> ",",D.dullyellow "status" <> ","
                  ,"or","whatever","field","you","want","to","access."
                  ]
              )

        -- Parse.Expression

        MatchingName name ->
          Report.Report "EXPECTING A DEFINITION" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I just saw the type annotation for `" ++ Name.toChars name
                  ++ "` so I was expecting to see its definition here:"
              ,
                D.reflow $
                  "Type annotations always appear directly above the relevant\
                  \ definition, without anything else (even doc comments) in between."
              )
-}

{-
        EndOfFile ->
          Report.Report "EXPECTING END OF FILE" region [] $
            Report.toCodeSnippet source region Nothing
              (
                D.reflow $
                  "I was not expecting to see anything more here:"
              ,
                D.reflow $
                  "I think I have read all the declarations in the file and that there is nothing\
                  \ left to see, so whatever I am running into is confusing me a lot!"
              )

-}
{-

    TypeWithBadDefinition region annName defName ->
      Report.Report "ANNOTATION MISMATCH" region [] $
        Report.toCodeSnippet source region Nothing
          (
            D.reflow $
              "I see a `" <> Name.toChars annName
              <> "` annotation, but it is followed by a `"
              <> Name.toChars defName <> "` definition."
          ,
            D.fillSep
              ["The","annotation","and","definition","names","must","match!"
              ,"Is","there","a","typo","between"
              , D.dullyellow (D.fromName annName)
              ,"and"
              , D.dullyellow (D.fromName defName) <> "?"
              ]
          )


-- PARSE ERROR TO DOCS


problemToDocs :: Problem -> (D.Doc, D.Doc)
problemToDocs problem =
  case problem of
    Tab ->
      (
        "I ran into a tab, but tabs are not allowed in Elm files."
      ,
        "Replace the tab with spaces."
      )

    EndOfFile_Comment ->
      (
        "I got to the end of the file while parsing a multi-line comment."
      ,
        [
          "Multi-line comments look like {- comment -}, and it looks like\
          \ you are missing the closing marker."
        ,
          D.toSimpleHint $
            "Nested multi-line comments like {- this {- and this -} -} are allowed.\
            \ The opening and closing markers must be balanced though, just\
            \ like parentheses in normal code. Maybe that is the problem?"
        ]
      )

    EndOfFile_String ->
      (
        "I got to the end of the file while parsing a string."
      ,
        "Strings look like \"this\" with double quotes on each end.\
        \ Is the closing double quote missing in your code?"
      )

    EndOfFile_MultiString ->
      (
        "I got to the end of the file while parsing a multi-line string."
      ,
        "Multi-line strings look like \"\"\"this\"\"\" with three double quotes\
        \ on each end. Is the closing triple quote missing in your code?"
      )

    EndOfFile_Char ->
      (
        "I got to the end of the file while parsing a character."
      ,
        "Characters look like 'c' with single quotes on each end.\
        \ Is the closing single quote missing in your code?"
      )

    NewLineInString ->
      (
        "This string is missing the closing quote."
      ,
        [
          "Elm strings like \"this\" cannot contain newlines."
        ,
          D.toSimpleHint $
            "For strings that CAN contain newlines, say \"\"\"this\"\"\" for Elm’s\
            \ multi-line string syntax. It allows unescaped newlines and double quotes."
        ]
      )

    NewLineInChar ->
      (
        "This character is missing the closing quote."
      ,
        "Elm characters must start and end with a single quote. Valid examples\n\
        \ include 'a', 'b', '\n', 'ø', and '\\u{00F8}' for unicode code points."
      )

    BadNumberDot numberBeforeDot ->
      (
        "Numbers cannot end with a decimal points."
      ,
        let
          number =
            D.fromString (show numberBeforeDot)
        in
        "Saying " <> D.green number <> " or " <> D.green (number <> ".0") <> " will work though!"
      )

    BadNumberEnd ->
      (
        "Numbers cannot have letters or underscores in them."
      ,
        "Maybe a space is missing between a number and a variable?"
      )

    BadNumberExp ->
      (
        "If you put the letter E in a number, it should followed by more digits."
      ,
        "If you want to say 1000, you can also say 1e3.\
        \ You cannot just end it with an E though!"
      )

    BadNumberHex ->
      (
        "I see the start of a hex number, but not the end."
      ,
        "A hex number looks like 0x123ABC, where the 0x is followed by hexidecimal\
        \ digits. Valid hexidecimal digits include: 0123456789abcdefABCDEF"
      )

    BadNumberZero ->
      (
        "Normal numbers cannot start with zeros. Take the zeros off the front."
      ,
        "Only numbers like 0x0040 or 0.25 can start with a zero."
      )

    BadUnderscore _ ->
      (
        "Variable names cannot start with an underscore like this:"
      ,
        "Delete the underscore and it shoulld be fine!"
      )

    BadOp op stack ->
      case op of
        HasType ->
          badOp stack "A" "\"has type\" operator"
            "type annotations and record types"
            "Maybe you want :: instead? Or maybe something is indented too much?"

        Equals ->
          (
            "I was not expecting this equals sign"
            <> contextToString " here" " while parsing " stack <> "."
          ,
            toBadEqualsHint stack
          )

        Arrow ->
          if isCaseRelated stack then
            (
              "I ran into a stray arrow while parsing this `case` expression."
            ,
              D.reflow $
                "All branches in a `case` must be indented the exact\
                \ same amount, so the patterns are vertically\
                \ aligned. Maybe this branch is indented too much?"
            )

          else
            badOp stack "An" "arrow"
              "cases expressions and anonymous functions"
              "Maybe you want > or >= instead?"

        Pipe ->
          badOp stack "A" "vertical bar"
            "type declarations"
            "Maybe you want || instead?"

        Dot ->
          (
            "I was not expecting this dot."
          ,
            D.reflow $
              "Dots are for record access and decimal points, so\
              \ they cannot float around on their own. Maybe\
              \ there is some extra whitespace?"
          )

    Theories stack allTheories ->
      (
        D.reflow $
          "Something went wrong while parsing " <> contextToString "your code" "" stack <> "."
      ,
        case Set.toList (Set.fromList allTheories) of
          [] ->
            D.stack
              [ D.reflow $
                  "I do not have any suggestions though!"
              , D.reflow $
                  "Can you get it down to a <http://sscce.org> and share it at\
                  \ <https://github.com/elm/error-message-catalog/issues>?\
                  \ That way we can figure out how to give better advice!"
              ]

          [theory] ->
            D.reflow $
              "I was expecting to see "
              <> addPeriod (theoryToString stack theory)

          theories ->
            D.vcat $
              [ "I was expecting:"
              , ""
              ]
              ++ map (bullet . theoryToString stack) theories
      )



-- BAD OP HELPERS


badOp :: ContextStack -> String -> String -> String -> String -> ( D.Doc, D.Doc )
badOp stack article opName setting hint =
  (
    D.reflow $
      "I was not expecting this " <> opName
      <> contextToString " here" " while parsing " stack <> "."
  ,
    D.reflow $
      article <> " " <> opName <> " should only appear in "
      <> setting <> ". " <> hint
  )


toBadEqualsHint :: ContextStack -> D.Doc
toBadEqualsHint stack =
  case stack of
    [] ->
      D.reflow $
        "Maybe you want == instead? Or maybe something is indented too much?"

    (ExprRecord, _) : _ ->
      D.reflow $
        "Records look like { x = 3, y = 4 } with the equals sign right\
        \ after the field name. Maybe you forgot a comma?"

    (Definition _, _) : rest ->
      D.reflow $
        "Maybe this is supposed to be a separate definition? If so, it\
        \ is indented too far. "
        <>
        if any ((==) ExprLet . fst) rest then
          "All definitions in a `let` expression must be vertically aligned."
        else
          "Spaces are not allowed before top-level definitions."

    _ : rest ->
      toBadEqualsHint rest



isCaseRelated :: ContextStack -> Bool
isCaseRelated stack =
  case stack of
    [] ->
      False

    (context, _) : rest ->
      context == ExprCase || isCaseRelated rest



-- CONTEXT


contextToString :: String -> String -> ContextStack -> String
contextToString defaultString prefixString stack =
  case stack of
    [] ->
      defaultString

    (context, _) : rest ->
      let anchor = getAnchor rest in
      prefixString <>
      case context of
        ExprIf -> "an `if` expression" <> anchor
        ExprLet -> "a `let` expression" <> anchor
        ExprFunc -> "an anonymous function" <> anchor
        ExprCase -> "a `case` expression" <> anchor
        ExprList -> "a list" <> anchor
        ExprTuple -> "an expression (in parentheses)" <> anchor
        ExprRecord -> "a record" <> anchor
        Definition name -> Name.toChars name <> "'s definition"
        Annotation name -> Name.toChars name <> "'s type annotation"
        TypeTuple -> "a type (in parentheses)" <> anchor
        TypeRecord -> "a record type" <> anchor
        PatternList -> "a list pattern" <> anchor
        PatternTuple -> "a pattern (in parentheses)" <> anchor
        PatternRecord -> "a record pattern" <> anchor
        Module -> "a module declaration"
        Import -> "an import"
        TypeUnion -> "a union type"
        TypeAlias -> "a type alias"
        Infix -> "an infix declaration"
        Port -> "a port declaration"


getAnchor :: ContextStack -> String
getAnchor stack =
  case stack of
    [] ->
      ""

    (context, _) : rest ->
      case context of
        Definition name ->
          " in " <> Name.toChars name <> "'s definition"

        Annotation name ->
          " in " <> Name.toChars name <> "'s type annotation"

        _ ->
          getAnchor rest



-- THEORY HELPERS


bullet :: String -> D.Doc
bullet point =
  D.hang 4 ("  - " <> D.fillSep (map D.fromString (words point)))


addPeriod :: String -> String
addPeriod msg =
  if last msg `elem` ['`', ')', '.', '!', '?'] then
    msg
  else
    msg <> "."


theoryToString :: ContextStack -> Theory -> String
theoryToString context theory =
  case theory of
    Keyword keyword ->
      "the `" <> keyword <> "` keyword"

    Symbol symbol ->
      case symbol of
        "=" -> equalsTheory context
        "->" -> "an arrow (->) followed by an expression"
        ":" -> "the \"has type\" symbol (:) followed by a type"
        "," -> "a comma"
        "|" -> barTheory context
        "::" -> "the cons operator (::) followed by more list elements"
        "." -> "a dot (.)"
        "-" -> "a minus sign (-)"
        "_" -> "an underscore"
        "(" -> "a left paren, for grouping or starting tuples"
        ")" -> "a closing paren"
        "[" -> "a left square bracket, for starting lists"
        "]" -> "a right square bracket, to end a list"
        "{" -> "a left curly brace, for starting records"
        "}" -> "a right curly brace, to end a record"
        "{-|" -> "a doc comment, like {-| this -}" --}
        _ -> "the (" <> symbol <> ") symbol"

    LowVar ->
      "a lower-case variable, like `x` or `user`"

    CapVar ->
      "an upper-case variable, like `Maybe` or `Just`"

    InfixOp ->
      "an infix operator, like (+) or (==)"

    Digit ->
      "a digit from 0 to 9"

    BadSpace ->
      badSpace context

    Expecting next ->
      case next of
        Decl -> "a declaration, like `x = 5` or `type alias Model = { ... }`"
        Expr -> "an expression, like x or 42"
        AfterOpExpr op -> "an expression after that (" <> Name.toChars op <> ") operator, like x or 42"
        ElseBranch -> "an `else` branch. An `if` must handle both possibilities."
        Arg -> "an argument, like `name` or `total`"
        Pattern -> "a pattern, like `name` or (Just x)"
        Type -> "a type, like Int or (List String)"
        Listing -> "a list of exposed values and types, like (..) or (x,y,z)"
        Exposing -> "something like `exposing (..)`"


equalsTheory :: ContextStack -> String
equalsTheory stack =
  case stack of
    [] ->
      "an equals sign (=)"

    (context, _) : rest ->
      case context of
        ExprRecord -> "an equals sign (=) followed by an expression"
        Definition name -> "an equals sign (=) followed by " <> Name.toChars name <> "'s definition"
        TypeUnion -> "an equals sign (=) followed by the first union type constructor"
        TypeAlias -> "an equals sign (=) followed by the aliased type"
        _ -> equalsTheory rest


barTheory :: ContextStack -> String
barTheory stack =
  case stack of
    [] ->
      "a vertical bar (|)"

    (context, _) : rest ->
      case context of
        ExprRecord -> "a vertical bar (|) followed by the record fields you want to update"
        TypeRecord -> "a vertical bar (|) followed by some record field types"
        TypeUnion -> "a vertical bar (|) followed by more union type constructors"
        _ -> barTheory rest


badSpace :: ContextStack -> String
badSpace stack =
  case stack of
    [] ->
      "more indentation? I was not done with that last thing yet."

    (context, _) : rest ->
      case context of
        ExprIf -> "the end of that `if`" <> badSpaceExprEnd rest
        ExprLet -> "the end of that `let`" <> badSpaceExprEnd rest
        ExprFunc -> badSpace rest
        ExprCase -> "more of that `case`" <> badSpaceExprEnd rest
        ExprList -> "the end of that list" <> badSpaceExprEnd rest
        ExprTuple -> "a closing paren" <> badSpaceExprEnd rest
        ExprRecord -> "the end of that record" <> badSpaceExprEnd rest
        Definition name -> "the rest of " <> Name.toChars name <> "'s definition" <> badSpaceExprEnd stack
        Annotation name -> "the rest of " <> Name.toChars name <> "'s type annotation" <> badSpaceEnd
        TypeTuple -> "a closing paren" <> badSpaceEnd
        TypeRecord -> "the end of that record" <> badSpaceEnd
        PatternList -> "the end of that list" <> badSpaceEnd
        PatternTuple -> "a closing paren" <> badSpaceEnd
        PatternRecord -> "the end of that record" <> badSpaceEnd
        Module -> "something like `module Main exposing (..)`"
        Import -> "something like `import Html exposing (..)`"
        TypeUnion -> "more of that union type" <> badSpaceEnd
        TypeAlias -> "more of that type alias" <> badSpaceEnd
        Infix -> "more of that infix declaration" <> badSpaceEnd
        Port -> "more of that port declaration" <> badSpaceEnd


badSpaceEnd :: String
badSpaceEnd =
  ". Maybe you forgot some code? Or you need more indentation?"


badSpaceExprEnd :: ContextStack -> String
badSpaceExprEnd stack =
  case stack of
    [] ->
      badSpaceEnd

    (Definition name, A.Position _ column) : _ ->
      let
        ending =
          if column <= 1 then
            "to be indented?"
          else
            "more indentation? (Try " <> show (column + 1) <> "+ spaces.)"
      in
        ". Maybe you forgot some code? Or maybe the body of `"
        <> Name.toChars name
        <> "` needs " <> ending

    _ : rest ->
      badSpaceExprEnd rest
-}
