
module Dict (empty,singleton,insert
            ,lookup,findWithDefault
            ,remove,member
            ,foldl,foldr,map
            ,union,intersect,diff
            ,keys,values
            ,toList,fromList
            ) where

import Maybe as Maybe
import Native.Error as Error
import List as List

data NColor = Red | Black

data Dict k v = Node NColor k v (Dict k v) (Dict k v) | Empty

-- Create an empty dictionary.
empty : Dict k v
empty = Empty

{-- Helpers for checking invariants

-- Check that the tree has an equal number of black nodes on each path
equal_pathLen t = 
  let path_numBlacks t =
     case t of
     { Empty -> 1
     ; Node col _ _ l r ->
          let { bl = path_numBlacks l ; br = path_numBlacks r } in
          if bl /= br || bl == 0-1 || br == 0-1
              then 0-1
              else bl + (if col == Red then 0 else 1)
     }
  in 0-1 /= path_numBlacks t

rootBlack t = 
  case t of
  { Empty -> True
  ; Node Black _ _ _ _ -> True
  ; _ -> False }

redBlack_children t = 
  case t of 
  { Node Red _ _ (Node Red _ _ _ _) _ -> False
  ; Node Red _ _ _ (Node Red _ _ _ _) -> False
  ; Empty -> True
  ; Node _ _ _ l r -> redBlack_children l && redBlack_children r
  }

findExtreme f t =
  case t of
  { Empty -> Nothing
  ; Node c k _ l r ->
      case findExtreme f (f (l,r)) of
      { Nothing -> Just k
      ; Just k' -> Just k' }
  }
               
findminRbt t = findExtreme fst t
findmaxRbt t = findExtreme snd t

-- "Option LT than"
-- Returns True if either xo or yo is Nothing
-- Otherwise returns the result of comparing the values using f

optionRelation f u xo yo =
  case (xo,yo) of
  { (Nothing,_) -> u
  ; (_,Nothing) -> u
  ; (Just x, Just y) -> f x y }

olt  xo yo = optionRelation (< ) True xo yo
olte xo yo = optionRelation (<=) True xo yo

ordered t =
  case t of
  { Empty -> True
  ; Node c k v l r ->
      let (lmax,rmin) = (findmaxRbt l, findminRbt r) in
      olte lmax (Just k) && olte (Just k) rmin && ordered l && ordered r
  }

-- Check that there aren't any right red nodes in the tree *)
leftLeaning t = 
  case t of
  { Empty -> True
  ; Node _ _ _ (Node Black _ _ _ _) (Node Red _ _ _ _) -> False
  ; Node _ _ _ Empty (Node Red _ _ _ _) -> False
  ; Node _ _ _ l r -> (leftLeaning l) && (leftLeaning r)
  }

invariants_hold t =
  ordered t && rootBlack t && redBlack_children t && 
  equal_pathLen t && leftLeaning t

--** End invariant helpers *****
--}


min : Dict k v -> (k,v)
min t =
  case t of 
    Node _ k v Empty _ -> (k,v)
    Node _ _ _ l _ -> min l
    Empty -> Error.raise "(min Empty) is not defined"

{--
max t =
  case t of 
  { Node _ k v _ Empty -> (k,v)
  ; Node _ _ _ _ r -> max r
  ; Empty -> Error.raise "(max Empty) is not defined"
  }
--}

-- Lookup the value associated with a key.
lookup : k -> Dict k v -> Maybe v
lookup k t =
 case t of
   Empty -> Nothing
   Node _ k' v l r ->
    case compare k k' of
      LT -> lookup k l
      EQ -> Just v
      GT -> lookup k r

-- Find the value associated with a key. If the key is not found, return the default value.
findWithDefault : v -> k -> Dict k v -> v
findWithDefault base k t =
 case t of
   Empty -> base
   Node _ k' v l r ->
    case compare k k' of
      LT -> findWithDefault base k l
      EQ -> v
      GT -> findWithDefault base k r

{--
-- Find the value associated with a key. If the key is not found, there will be a runtime error.
find k t =
 case t of
 { Empty -> Error.raise "Key was not found in dictionary!"
 ; Node _ k' v l r ->
    case compare k k' of
    { LT -> find k l
    ; EQ -> v
    ; GT -> find k r }
 }
--}

-- Determine if a key is in a dictionary.
member : k -> Dict k v -> Bool
-- Does t contain k?
member k t = Maybe.isJust $ lookup k t

rotateLeft : Dict k v -> Dict k v
rotateLeft t =
 case t of
   Node cy ky vy a (Node cz kz vz b c) -> Node cy kz vz (Node Red ky vy a b) c
   _ -> Error.raise "rotateLeft of a node without enough children"

-- rotateRight -- the reverse, and 
-- makes Y have Z's color, and makes Z Red.
rotateRight : Dict k v -> Dict k v
rotateRight t =
 case t of
   Node cz kz vz (Node cy ky vy a b) c -> Node cz ky vy a (Node Red kz vz b c)
   _ -> Error.raise "rotateRight of a node without enough children"

rotateLeftIfNeeded : Dict k v -> Dict k v
rotateLeftIfNeeded t =
 case t of 
   Node _ _ _ _ (Node Red _ _ _ _) -> rotateLeft t
   _ -> t

rotateRightIfNeeded : Dict k v -> Dict k v
rotateRightIfNeeded t =
 case t of 
   Node _ _ _ (Node Red _ _ (Node Red _ _ _ _) _) _ -> rotateRight t
   _ -> t

otherColor c = case c of { Red -> Black ; Black -> Red }

color_flip : Dict k v -> Dict k v
color_flip t =
 case t of
   Node c1 bk bv (Node c2 ak av la ra) (Node c3 ck cv lc rc) -> 
       Node (otherColor c1) bk bv
              (Node (otherColor c2) ak av la ra)
              (Node (otherColor c3) ck cv lc rc)
   _ -> Error.raise "color_flip called on a Empty or Node with a Empty child"

color_flipIfNeeded : Dict k v -> Dict k v
color_flipIfNeeded t = 
 case t of
   Node _ _ _ (Node Red _ _ _ _) (Node Red _ _ _ _) -> color_flip t
   _ -> t

fixUp t = color_flipIfNeeded (rotateRightIfNeeded (rotateLeftIfNeeded t))

ensureBlackRoot : Dict k v -> Dict k v
ensureBlackRoot t = 
  case t of
    Node Red k v l r -> Node Black k v l r
    _ -> t
     
-- Insert a key-value pair into a dictionary. Replaces value when there is a collision.
-- Invariant: t is a valid left-leaning rb tree *)
insert : k -> v -> Dict k v -> Dict k v
insert k v t =
  let ins t =
      case t of
        Empty -> Node Red k v Empty Empty
        Node c k' v' l r ->
          let h = case compare k k' of
                    LT -> Node c k' v' (ins l) r
                    EQ -> Node c k' v  l r  -- replace
                    GT -> Node c k' v' l (ins r)
          in  fixUp h
  in  ensureBlackRoot (ins t)
{--
      if not (invariants_hold t) then
          Error.raise "invariants broken before insert"
      else (let new_t = ensureBlackRoot (ins t) in
            if not (invariants_hold new_t) then
                Error.raise "invariants broken after insert"
            else new_t)
--}

-- Create a dictionary with one key-value pair.
singleton : k -> v -> Dict k v
singleton k v = insert k v Empty

isRed : Dict k v -> Bool
isRed t =
  case t of
    Node Red _ _ _ _ -> True
    _ -> False

isRedLeft : Dict k v -> Bool
isRedLeft t =
  case t of
    Node _ _ _ (Node Red _ _ _ _) _ -> True
    _ -> False

isRedLeftLeft : Dict k v -> Bool
isRedLeftLeft t =
  case t of
    Node _ _ _ (Node _ _ _ (Node Red _ _ _ _) _) _ -> True
    _ -> False

isRedRight : Dict k v -> Bool
isRedRight t =
  case t of
    Node _ _ _ _ (Node Red _ _ _ _) -> True
    _ -> False

isRedRightLeft : Dict k v -> Bool
isRedRightLeft t =
  case t of
    Node _ _ _ _ (Node _ _ _ (Node Red _ _ _ _) _) -> True
    _ -> False

moveRedLeft : Dict k v -> Dict k v
moveRedLeft t = 
  let t' = color_flip t in
  case t' of
    Node c k v l r ->
        case r of
          Node _ _ _ (Node Red _ _ _ _) _ ->
              color_flip (rotateLeft (Node c k v l (rotateRight r)))
          _ -> t'
    _ -> t'

moveRedRight : Dict k v -> Dict k v
moveRedRight t =
  let t' = color_flip t in
  if isRedLeftLeft t' then color_flip (rotateRight t') else t'

moveRedLeftIfNeeded : Dict k v -> Dict k v
moveRedLeftIfNeeded t =
  if not (isRedLeft t) && not (isRedLeftLeft t) then moveRedLeft t else t

moveRedRightIfNeeded : Dict k v -> Dict k v
moveRedRightIfNeeded t =
  if not (isRedRight t) && not (isRedRightLeft t) then moveRedRight t else t
  
deleteMin : Dict k v -> Dict k v
deleteMin t = 
  let del t =
    case t of 
      Node _ _ _ Empty _ -> Empty
      _ -> case moveRedLeftIfNeeded t of
             Node c k v l r -> fixUp (Node c k v (del l) r)
             Empty -> Empty
  in  ensureBlackRoot (del t)

{--
deleteMax t =
  let del t =
      let t' = if isRedLeft t then rotateRight t else t in
      case t' of
      { Node _ _ _ _ Empty -> Empty
      ; _ -> let t'' = moveRedRightIfNeeded t' in
             case t'' of
             { Node c k v l r -> fixUp (Node c k v l (del r))
             ; Empty -> Empty } }
  in  ensureBlackRoot (del t)
--}

-- Remove a key-value pair from a dictionary. If the key is not found, no changes are made.
remove : k -> Dict k v -> Dict k v
remove k t = 
  let eq_and_noRightNode t =
          case t of { Node _ k' _ _ Empty -> k == k' ; _ -> False }
      eq t = case t of { Node _ k' _ _ _ -> k == k' ; _ -> False }
      delLT t = case moveRedLeftIfNeeded t of 
                  Node c k' v l r -> fixUp (Node c k' v (del l) r)
                  Empty -> Error.raise "delLT on Empty"
      delEQ t = case t of -- Replace with successor
                  Node c _ _ l r -> let (k',v') = min r in
                                      fixUp (Node c k' v' l (deleteMin r))
                  Empty -> Error.raise "delEQ called on a Empty"
      delGT t = case t of
                  Node c k' v l r -> fixUp (Node c k' v l (del r))
                  Empty -> Error.raise "delGT called on a Empty"
      del t = case t of 
                Empty -> Empty
                Node _ k' _ _ _ ->
                    if k < k' then delLT t else
                        let u = if isRedLeft t then rotateRight t else t in
                        if eq_and_noRightNode u then Empty else
                            let t' = moveRedRightIfNeeded t in
                            if eq t' then delEQ t' else delGT t'
  in  if member k t then ensureBlackRoot (del t) else t
{--
      if not (invariants_hold t) then
          Error.raise "invariants broken before remove"
      else (let t' = ensureBlackRoot (del t) in
            if invariants_hold t' then t' else
                Error.raise "invariants broken after remove")
--}

-- Apply a function to all values in a dictionary.
map : (a -> b) -> Dict k a -> Dict k b
map f t =
  case t of
    Empty -> Empty
    Node c k v l r -> Node c k (f v) (map f l) (map f r)

-- Fold over the key-value pairs in a dictionary, in order from lowest key to highest key.
foldl : (k -> v -> b -> b) -> b -> Dict k v -> b
foldl f acc t =
  case t of
    Empty -> acc
    Node _ k v l r -> foldl f (f k v (foldl f acc l)) r

-- Fold over the key-value pairs in a dictionary, in order from highest key to lowest key.
foldr : (k -> v -> b -> b) -> b -> Dict k v -> b
foldr f acc t =
  case t of
    Empty -> acc
    Node _ k v l r -> foldr f (f k v (foldr f acc r)) l

-- Combine two dictionaries. If there is a collision, preference is given to the first dictionary.
union : Dict k v -> Dict k v -> Dict k v
union t1 t2 = foldl insert t2 t1

-- Keep a key-value pair when its key appears in the second dictionary. Preference is given to values in the first dictionary.
intersect : Dict k v -> Dict k v -> Dict k v
intersect t1 t2 =
 let combine k v t = if k `member` t2 then insert k v t else t
 in  foldl combine empty t1

-- Keep a key-value pair when its key does not appear in the second dictionary. Preference is given to the first dictionary.
diff : Dict k v -> Dict k v -> Dict k v
diff t1 t2 = foldl (\k v t -> remove k t) t1 t2

-- Get all of the keys in a dictionary.
keys : Dict k v -> [k]
keys t   = foldr (\k v acc -> k :: acc) [] t

-- Get all of the values in a dictionary.
values : Dict k v -> [v]
values t = foldr (\k v acc -> v :: acc) [] t

-- Convert a dictionary into an association list of key-value pairs.
toList : Dict k v -> [(k,v)]
toList t = foldr (\k v acc -> (k,v) :: acc) [] t

-- Convert an association list into a dictionary.
fromList : [(k,v)] -> Dict k v
fromList assocs = List.foldl (uncurry insert) empty assocs
