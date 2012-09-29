
module Types.Hints (hints) where

import Control.Monad (liftM,mapM)
import Control.Arrow (first)
import Types
import Types.Substitutions (rescheme)


--------  Text and Elements  --------

str2elem = hasType (string ==> element) [ "plainText" ]

textToText = [ "header", "italic", "bold", "underline"
             , "overline", "strikeThrough", "monospace" ]

textAttrs = [ "toText" -: string ==> text
            , "typeface" -: string ==> text ==> text
            , "link"   -:: string ==> a ==> a
            , numScheme (\t -> t ==> text ==> text) "Text.height"
            ] ++ hasType (text ==> text) textToText

elements = let iee = int ==> element ==> element in
           [ "flow"    -: direction ==> listOf element ==> element
           , "layers"  -: listOf element ==> element
           , "text"    -: text ==> element
           , "image"   -: int ==> int ==> string ==> element
           , "video"   -: int ==> int ==> string ==> element
           , "opacity" -: float ==> element ==> element
           , "width"   -: iee
           , "height"  -: iee
           , "size"    -: int ==> iee
           , "widthOf" -: element ==> int
           , "heightOf"-: element ==> int
           , "sizeOf"  -: element ==> pairOf int
           , "color"   -: color ==> element ==> element
           , "container" -: int ==> int ==> position ==> element ==> element
           , "spacer" -: int ==> int ==> element
           , "rightedText"  -: text ==> element
           , "centeredText"  -: text ==> element
           , "justifiedText" -: text ==> element
           , "asText" -:: a ==> element 
           , "show" -:: a ==> text
           , "collage" -: int ==> int ==> listOf form ==> element
           , "fittedImage" -: int ==> int ==> string ==> element
           ]

directions = hasType direction ["up","down","left","right","inward","outward"]
positions =
    hasType position ["topLeft","midLeft","bottomLeft","midTop","middle"
                     ,"midBottom","topRight","midRight","bottomRight"] ++
    hasType (location ==> position)
                ["topLeftAt","bottomLeftAt","middleAt","topRightAt","bottomRightAt"] ++
    [ "absolute" -: int ==> location, "relative" -: float ==> location ]
colors = [ numScheme (\n -> n ==> n ==> n ==> color) "rgb"
         , numScheme (\n -> n ==> n ==> n ==> n ==> color) "rgba"
         ] ++ hasType color ["red","green","blue","black","white"
                            ,"yellow","cyan","magenta","grey","gray"]

lineTypes = [ numScheme (\n -> listOf (pairOf n) ==> line) "line"
            , numScheme (\n -> pairOf n ==> pairOf n ==> line) "segment"
            , "customLine" -: listOf int ==> color ==> line ==> form
            ] ++ hasType (color ==> line ==> form) ["solid","dashed","dotted"]

shapes = [ twoNums (\n m -> listOf (pairOf n) ==> pairOf m ==> shape) "polygon"
         , "filled"        -: color ==> shape ==> form
         , "outlined"      -: color ==> shape ==> form
         , "textured"      -: string ==> shape ==> form
         , "customOutline" -: listOf int ==> color ==> shape ==> form
         ] ++ map (twoNums (\n m -> n ==> n ==> pairOf m ==> shape)) [ "ngon"
                                                                     , "rect"
                                                                     , "oval" ]

collages = [ numScheme (\n -> pairOf n ==> element ==> form) "toForm"
           , numScheme (\n -> string ==> n ==> n ==> pairOf n ==> form) "sprite"
           , numScheme (\n -> n ==> n ==> form ==> form) "move"
           , numScheme (\n -> n ==> form ==> form) "rotate"
           , numScheme (\n -> n ==> form ==> form) "scale"
           ]

--------  Foreign  --------

casts =
  [ "castJSBoolToBool"       -: jsBool ==> bool
  , "castBoolToJSBool"       -: bool ==> jsBool
  , "castJSNumberToInt"      -: jsNumber ==> int
  , "castIntToJSNumber"      -: int ==> jsNumber
  , "castJSElementToElement" -: int ==> int ==> jsElement ==> element
  , "castElementToJSElement" -: element ==> jsElement
  , "castJSStringToString"   -: jsString ==> string
  , "castStringToJSString"   -: string ==> jsString
  , "castJSNumberToFloat"    -: jsNumber ==> float 
  , "castFloatToJSNumber"    -: float ==> jsNumber
  ]

castToTuple n = (,) name $ Forall [1..n] [] (jsTuple vs ==> tupleOf vs)
    where vs = map VarT [1..n]
          name = "castJSTupleToTuple" ++ show n
castToJSTuple n = (,) name $ Forall [1..n] [] (tupleOf vs ==> jsTuple vs)
    where vs = map VarT [1..n]
          name = "castTupleToJSTuple" ++ show n

polyCasts =
  map castToTuple [2..5] ++ map castToJSTuple [2..5] ++
  [ "castJSArrayToList"   -:: jsArray a ==> listOf a
  , "castListToJSArray"   -:: listOf a ==> jsArray a
  ]

json =
  [ "JsonString" -: string ==> jsonValue
  , "JsonBool"   -: bool   ==> jsonValue
  , "JsonNull"   -: jsonValue
  , "JsonArray"  -: listOf jsonValue ==> jsonValue
  , "JsonObject" -: jsonObject ==> jsonValue
  , numScheme (\n -> n ==> jsonValue) "JsonNumber"
  , "toPrettyString" -: string ==> jsonObject ==> string
  , "toPrettyJSString" -: string ==> jsonObject ==> jsString
  , "toJSString" -: jsonObject ==> jsString
  ]


--------  Signals  --------

sig n name = (,) name $ Forall [1..n] [] (fn ts ==> fn (map signalOf ts))
    where fn = foldr1 (==>)
          ts = map VarT [1..n]

signals =
    [ sig 1 "constant"
    , sig 2 "lift" 
    , sig 3 "lift2"
    , sig 4 "lift3"
    , sig 5 "lift4"
    , "foldp"     -:: (a ==> b ==> b) ==> b ==> signalOf a ==> signalOf b
    , "foldp1"    -:: (a ==> b ==> b) ==> (a ==> b) ==> signalOf a ==> signalOf b
    , "randomize" -:: int ==> int ==> signalOf a ==> signalOf int
    , "count"     -:: signalOf a ==> signalOf int
    , "keepIf"    -:: (a==>bool) ==> a ==> signalOf a ==> signalOf a
    , "dropIf"    -:: (a==>bool) ==> a ==> signalOf a ==> signalOf a
    , "keepWhen"  -:: signalOf bool ==>a==> signalOf a ==> signalOf a
    , "dropWhen"  -:: signalOf bool ==>a==> signalOf a ==> signalOf a
    , "dropRepeats" -:: signalOf a ==> signalOf a
    , "sampleOn" -:: signalOf a ==> signalOf b ==> signalOf b
    ]

concreteSignals = 
  [ "keysDown"    -: signalOf (listOf int)
  , "charPressed" -: signalOf (maybeOf int)
  , "inRange"     -: int ==> int ==> signalOf int
  , timeScheme "every"  (\t -> t ==> signalOf t)
  , timeScheme "before" (\t -> t ==> signalOf bool)
  , timeScheme "after"  (\t -> t ==> signalOf bool)
  , "dimensions"  -: signalOf point
  , "position"    -: signalOf point
  , "x"           -: signalOf int
  , "y"           -: signalOf int
  , "isDown"      -: signalOf bool
  , "isClicked"   -: signalOf bool
  , "textField"   -: string ==> tupleOf [element, signalOf string]
  , "password"    -: string ==> tupleOf [element, signalOf string]
  , "textArea"    -: int ==> int ==> tupleOf [element, signalOf string]
  , "checkBox"    -: bool ==> tupleOf [element, signalOf bool]
  , "button"      -: string ==> tupleOf [element, signalOf bool]
  , "stringDropDown" -: listOf string ==> tupleOf [element, signalOf string]
  ]

--------  Math and Binops  --------

binop t = t ==> t ==> t
scheme1 super t name =
    (name, Forall [0] [ Context ("`" ++ name ++ "'") $ VarT 0 :<: super
                      ] (t (VarT 0)))
scheme2 s1 s2 t name =
    (name, Forall [0,1] [ Context ("`" ++ name ++ "'") $ VarT 0 :<: s1
                        , Context ("`" ++ name ++ "'") $ VarT 1 :<: s2
                        ] (t (VarT 0) (VarT 1)))
numScheme t name = scheme1 number t name
timeScheme name t = scheme1 time t name
twoNums f name = scheme2 number number f name

math =
  map (numScheme (\t -> t ==> binop t)) ["clamp"] ++
  map (numScheme (\t -> binop t)) ["+","-","*","max","min"] ++
  [ numScheme (\t -> t ==> t) "abs" ] ++
  hasType (binop float) [ "/", "logBase" ] ++
  hasType (binop int) ["rem","div","mod"] ++
  hasType (float ==> float) ["sin","cos","tan","asin","acos","atan","sqrt"] ++
  hasType float ["pi","e"] ++
  hasType (int ==> float) ["toFloat","castIntToFloat"] ++
  hasType (float ==> int) ["round","floor","ceiling","truncate"]

bools =
  [ "not" -: bool ==> bool ] ++
  hasType (binop bool) ["&&","||"] ++
  map (scheme1 comparable (\t -> t ==> t ==> bool))  ["<",">","<=",">="] ++
  [ ( "compare"
    , Forall [0,1] [ Context "`compare'" $ VarT 0 :<: comparable ] (VarT 0 ==> VarT 0 ==> VarT 1) )
  ]

--------  Polymorphic Functions  --------

[a,b,c] = map VarT [1,2,3]

infix 8 -::
name -:: tipe = (name, Forall [1,2,3] [] tipe)

funcs =
    [ "id"   -:: a ==> a
    , "=="   -:: a ==> a ==> bool
    , "/="   -:: a ==> a ==> bool
    , "flip" -:: (a ==> b ==> c) ==> (b ==> a ==> c)
    , "."    -:: (b ==> c) ==> (a ==> b) ==> (a ==> c)
    , "$"    -:: (a ==> b) ==> a ==> b
    , ":"       -:: a ==> listOf a ==> listOf a
    , (,) "++" . Forall [0,1] [ Context "`++'" $ VarT 0 :<: appendable (VarT 1) ] $ VarT 0 ==> VarT 0 ==> VarT 0
    , "Cons"    -:: a ==> listOf a ==> listOf a 
    , "Nil"     -:: listOf a
    , "Just"    -:: a ==> maybeOf a
    , "Nothing" -:: maybeOf a
    , "curry"   -:: (tupleOf [a,b] ==> c) ==> a ==> b ==> c
    , "uncurry" -:: (a ==> b ==> c) ==> tupleOf [a,b] ==> c
    ] ++ map tuple [0..8]

tuple n = ("Tuple" ++ show n, Forall [1..n] [] $ foldr (==>) (tupleOf vs) vs)
    where vs = map VarT [1..n]

lists =
  [ "and"  -:: listOf bool ==> bool
  , "or"   -:: listOf bool ==> bool
  , numScheme (\n -> listOf n ==> listOf n) "sort"
  , "head"    -:: listOf a ==> a
  , "tail"    -:: listOf a ==> listOf a
  , "length"  -:: listOf a ==> int
  , "filter"  -:: (a ==> bool) ==> listOf a ==> listOf a
  , "foldr1"  -:: (a ==> a ==> a) ==> listOf a ==> a
  , "foldl1"  -:: (a ==> a ==> a) ==> listOf a ==> a
  , "scanl1"  -:: (a ==> a ==> a) ==> listOf a ==> a
  , "forall"  -:: (a ==> bool) ==> listOf a ==> bool
  , "exists"  -:: (a ==> bool) ==> listOf a ==> bool
  , "reverse" -:: listOf a ==> listOf a
  , "take"    -:: int ==> listOf a ==> listOf a
  , "drop"    -:: int ==> listOf a ==> listOf a
  , "partition"    -:: (a ==> bool) ==> listOf a ==> tupleOf [listOf a,listOf a]
  , "intersperse"  -:: a ==> listOf a ==> listOf a
  , "zip"   -:: listOf a ==>listOf b ==>listOf(tupleOf [a,b])
  , "map"   -:: (a ==> b) ==> listOf a ==> listOf b
  , "foldr" -:: (a ==> b ==> b) ==> b ==> listOf a ==> b
  , "foldl" -:: (a ==> b ==> b) ==> b ==> listOf a ==> b
  , "scanl" -:: (a ==> b ==> b) ==> b ==> listOf a ==> listOf b
  , (,) "concat"      . Forall [0,1]   [ Context "`concat'" $ VarT 0 :<: appendable (VarT 1) ] $
        listOf (VarT 0) ==> VarT 0
  , (,) "concatMap"   . Forall [0,1,2] [ Context "`concatMap'" $ VarT 0 :<: appendable (VarT 1) ] $
        (VarT 2 ==> VarT 0) ==> listOf (VarT 2) ==> VarT 0
  , (,) "intercalate" . Forall [0,1]   [ Context "`intercalate'" $ VarT 0 :<: appendable (VarT 1) ] $
        VarT 0 ==> listOf (VarT 0) ==> VarT 0
  , "zipWith" -:: (a ==> b ==> c) ==> listOf a ==> listOf b ==> listOf c
  ] ++ map (numScheme (\n -> listOf n ==> n)) [ "sum", "product"
                                              , "maximum", "minimum" ]

maybeFuncs =
  [ "maybe" -:: b ==> (a ==> b) ==> maybeOf a ==> b
  , "isJust" -:: maybeOf a ==> bool
  , "isNothing" -:: maybeOf a ==> bool
  , "fromMaybe" -:: a ==> maybeOf a ==> a
  , "consMaybe" -:: maybeOf a ==> listOf a ==> listOf a
  , "catMaybes" -:: listOf (maybeOf a) ==> listOf a
  , "catMaybes" -:: (a ==> maybeOf b) ==> listOf a ==> listOf b
  ]

--------  Everything  --------

hints = mapM (\(n,s) -> (,) n `liftM` rescheme s) hs
    where hs = concat [ funcs, lists, signals, math, bools, str2elem, textAttrs
                      , elements, directions, colors, lineTypes, shapes
                      , concreteSignals, casts, polyCasts, json, maybeFuncs
                      , positions, collages
                      ]
