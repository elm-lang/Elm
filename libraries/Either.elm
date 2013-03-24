
module Either where

import List

-- Represents any data that can take two different types.
--
-- This can also be used for error handling `(Either String a)` where error
-- messages are stored on the left, and the correct values (&ldquo;right&rdquo; values) are stored on the right.
data Either a b = Left a | Right b

-- Apply the first function to a `Left` and the second function to a `Right`.
-- This allows the extraction of a value from an `Either`.
either : (a -> c) -> (b -> c) -> Either a b -> c
either f g e = case e of { Left x -> f x ; Right y -> g y }

-- True if the value is a `Left`.
isLeft : Either a b -> Bool
isLeft e = case e of { Left  _ -> True ; _ -> False }

-- True if the value is a `Right`.
isRight : Either a b -> Bool
isRight e = case e of { Right _ -> True ; _ -> False }

-- Keep only the values held in `Left` values.
--lefts : [Either a b] -> [a]
lefts es = List.filter isLeft es

-- Keep only the values held in `Right` values.
--rights : [Either a b] -> [b]
rights es = List.filter isRight es

-- Split into two lists, lefts on the left and rights on the right. So we
-- have the equivalence: `(partition es == (lefts es, rights es))`
-- partition : [Either a b] -> ([a],[b])
partition es = List.partition isLeft es
