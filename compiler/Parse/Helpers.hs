module Parse.Helpers where

import Prelude hiding (until)
import Control.Applicative ((<$>),(<*>))
import Control.Monad
import Control.Monad.State
import Data.Char (isUpper)
import qualified Data.Set as Set
import qualified Data.Map as Map
import SourceSyntax.Helpers as Help
import SourceSyntax.Location as Location
import SourceSyntax.Expression
import SourceSyntax.PrettyPrint
import SourceSyntax.Declaration (Assoc)
import Text.Parsec hiding (newline,spaces,State)
import Text.Parsec.Indent

reserveds = [ "if", "then", "else"
            , "case", "of"
            , "let", "in"
            , "data", "type"
            , "module", "where"
            , "import", "as", "hiding", "open"
            , "export", "foreign" ]

jsReserveds :: Set.Set String
jsReserveds = Set.fromList
    [ "null", "undefined", "Nan", "Infinity", "true", "false", "eval"
    , "arguments", "int", "byte", "char", "goto", "long", "final", "float"
    , "short", "double", "native", "throws", "boolean", "abstract", "volatile"
    , "transient", "synchronized", "function", "break", "case", "catch"
    , "continue", "debugger", "default", "delete", "do", "else", "finally"
    , "for", "function", "if", "in", "instanceof", "new", "return", "switch"
    , "this", "throw", "try", "typeof", "var", "void", "while", "with", "class"
    , "const", "enum", "export", "extends", "import", "super", "implements"
    , "interface", "let", "package", "private", "protected", "public"
    , "static", "yield"
    ]

expecting = flip (<?>)

type OpTable = Map.Map String (Int, Assoc)
type IParser a = ParsecT String OpTable (State SourcePos) a

iParse :: IParser a -> String -> Either ParseError a
iParse = iParseWithTable "" Map.empty

iParseWithTable :: SourceName -> OpTable -> IParser a -> String -> Either ParseError a
iParseWithTable sourceName table aParser input =
  runIndent sourceName $ runParserT aParser table sourceName input

backslashed :: IParser Char
backslashed = do { char '\\'; c <- anyChar
                 ; return . read $ ['\'','\\',c,'\''] }

var :: IParser String
var = makeVar (letter <|> char '_' <?> "variable")

lowVar :: IParser String
lowVar = makeVar (lower <?> "lower case variable")
capVar :: IParser String
capVar = makeVar (upper <?> "upper case variable")

qualifiedVar :: IParser String
qualifiedVar = do
  vars <- many ((++) <$> capVar <*> string ".")
  (++) (concat vars) <$> lowVar

rLabel :: IParser String
rLabel = lowVar

innerVarChar :: IParser Char
innerVarChar = alphaNum <|> char '_' <|> char '\'' <?> "" 

makeVar :: IParser Char -> IParser String
makeVar p = do v <- (:) <$> p <*> many innerVarChar
               guard (v `notElem` reserveds)
               return v

reserved :: String -> IParser String
reserved word =
  try (string word >> notFollowedBy innerVarChar) >> return word
  <?> "reserved word '" ++ word ++ "'"

anyOp :: IParser String
anyOp = betwixt '`' '`' qualifiedVar <|> symOp <?> "infix operator (e.g. +, *, ||)"

symOp :: IParser String
symOp = do op <- many1 (satisfy Help.isSymbol)
           guard (op `notElem` [ "=", "..", "->", "--", "|", "\8594", ":" ])
           case op of
             "." -> notFollowedBy lower >> return op
             "\8728" -> return "."
             _   -> return op

arrow :: IParser String
arrow = string "->" <|> string "\8594" <?> "arrow (->)"

hasType :: IParser String
hasType = string ":" <?> "':' (a type annotation)'"


commitIf check p = commit <|> try p
    where commit = do (try $ lookAhead check) >> p

spaceySepBy1 :: IParser b -> IParser a -> IParser [a]
spaceySepBy1 sep p = do
  a <- p
  (a:) <$> many (commitIf (whitespace >> sep) (whitespace >> sep >> whitespace >> p))


commaSep1 :: IParser a -> IParser [a]
commaSep1 = spaceySepBy1 (char ',' <?> "comma ','")

commaSep :: IParser a -> IParser [a]
commaSep = option [] . commaSep1

semiSep1 :: IParser a -> IParser [a]
semiSep1 = spaceySepBy1 (char ';' <?> "semicolon ';'")

pipeSep1 :: IParser a -> IParser [a]
pipeSep1 = spaceySepBy1 (char '|' <?> "type divider '|'")

consSep1 :: IParser a -> IParser [a]
consSep1 = spaceySepBy1 (string "::" <?> "cons operator '::'")

dotSep1 :: IParser a -> IParser [a]
dotSep1 p = (:) <$> p <*> many (try (char '.') >> p)

spaceSep1 :: IParser a -> IParser [a]
spaceSep1 p =  (:) <$> p <*> spacePrefix p

spacePrefix p = constrainedSpacePrefix p (\_ -> return ())

constrainedSpacePrefix p constraint =
    many $ choice [ try (spacing >> lookAhead (oneOf "[({")) >> p
                  , try (spacing >> p)
                  ]
    where
      spacing = do
        n <- whitespace
        constraint n
        indented

failure msg = do
  inp <- getInput
  setInput ('x':inp)
  anyToken
  fail msg

followedBy a b = do x <- a ; b ; return x

betwixt a b c = do char a ; out <- c
                   char b <?> "closing '" ++ [b] ++ "'" ; return out

surround a z name p = do
  char a ; whitespace ; v <- p ; whitespace
  char z <?> unwords ["closing", name, show z]
  return v

braces   :: IParser a -> IParser a
braces   = surround '[' ']' "brace"

parens   :: IParser a -> IParser a
parens   = surround '(' ')' "paren"

brackets :: IParser a -> IParser a
brackets = surround '{' '}' "bracket"

addLocation :: (Pretty a) => IParser a -> IParser (Location.Located a)
addLocation expr = do
  (start, e, end) <- located expr
  return (Location.at start end e)

located :: IParser a -> IParser (SourcePos, a, SourcePos)
located p = do
  start <- getPosition
  e <- p
  end <- getPosition
  return (start, e, end)

accessible :: IParser (LExpr t v) -> IParser (LExpr t v)
accessible expr = do
  start <- getPosition
  ce@(L _ e) <- expr
  let rest f = do
        let dot = char '.' >> notFollowedBy (char '.')
        access <- optionMaybe (try dot <?> "field access (e.g. List.map)")
        case access of
          Nothing -> return ce
          Just _  -> accessible $ do
                       v <- var <?> "field access (e.g. List.map)"
                       end <- getPosition
                       return (Location.at start end (f v))
  case e of Var (c:cs) | isUpper c -> rest (\v -> Var (c:cs ++ '.':v))
                       | otherwise -> rest (Access ce)
            _ -> rest (Access ce)


spaces :: IParser String
spaces = concat <$> many1 (multiComment <|> string " ") <?> "spaces"

forcedWS :: IParser String
forcedWS = choice [ try $ (++) <$> spaces <*> (concat <$> many nl_space)
                  , try $ concat <$> many1 nl_space ]
    where nl_space = try ((++) <$> (concat <$> many1 newline) <*> spaces)

-- Just eats whitespace until the next meaningful character.
dumbWhitespace :: IParser String
dumbWhitespace = concat <$> many (spaces <|> newline)

whitespace :: IParser String
whitespace = option "" forcedWS <?> "whitespace"

freshLine :: IParser [[String]]
freshLine = try (many1 newline >> many space_nl) <|> try (many1 space_nl) <?> ""
    where space_nl = try $ spaces >> many1 newline

newline :: IParser String
newline = simpleNewline <|> lineComment <?> "newline"

simpleNewline :: IParser String
simpleNewline = try (string "\r\n") <|> string "\n"

lineComment :: IParser String
lineComment = do
  try (string "--")
  comment <- anyUntil $ simpleNewline <|> (eof >> return "\n")
  return ("--" ++ comment)

multiComment :: IParser String
multiComment = (++) <$> try (string "{-") <*> closeComment

closeComment :: IParser String
closeComment =
    anyUntil . choice $
                 [ try (string "-}") <?> "close comment"
                 , concat <$> sequence [ try (string "{-"), closeComment, closeComment ]
                 ]

until :: IParser a -> IParser b -> IParser b
until p end =  go
    where
      go = end <|> (p >> go)

anyUntil :: IParser String -> IParser String
anyUntil end = go
    where
      go = end <|> (:) <$> anyChar <*> go

ignoreUntil :: IParser a -> IParser (Maybe a)
ignoreUntil end = go
    where
      ignore p = const () <$> p
      filler = choice [ ignore multiComment
                      , ignore (markdown (\_ _ -> mzero))
                      , ignore anyChar
                      ]
      go = choice [ Just <$> end
                  , filler `until` choice [ const Nothing <$> eof, newline >> go ]
                  ]

onFreshLines :: (a -> b -> b) -> b -> IParser a -> IParser b
onFreshLines insert init thing = go init
    where
      go values = do
        optionValue <- ignoreUntil thing
        case optionValue of
          Nothing -> return values
          Just v  -> go (insert v values)

withSource :: IParser a -> IParser (String, a)
withSource p = do
  start  <- getParserState
  result <- p
  endPos <- getPosition
  setParserState start
  raw <- anyUntilPos endPos
  return (raw, result)

anyUntilPos :: SourcePos -> IParser String
anyUntilPos pos = go
    where
      go = do currentPos <- getPosition
              case currentPos == pos of
                True -> return []
                False -> (:) <$> anyChar <*> go

markdown :: (String -> [a] -> IParser (String, [a])) -> IParser (String, [a])
markdown interpolation = try (string "[markdown|") >> closeMarkdown "" []
    where
      closeMarkdown md stuff =
          choice [ do try (string "|]")
                      return (md, stuff)
                 , uncurry closeMarkdown =<< interpolation md stuff
                 , do c <- anyChar
                      closeMarkdown (md ++ [c]) stuff
                 ]