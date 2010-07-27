module Math.Spline.Knots
    ( Knots
    , knot, knotWithMultiplicity
    , knotsFromList, knotsFromListWithMultiplicity
    , numKnots, numDistinctKnots
    , knots, distinctKnots
    , knotMultiplicity, setKnotMultiplicity
    , totalMultiplicity
    , knotDomain
    ) where

import Prelude hiding (sum)
import Data.Foldable (Foldable(foldMap), sum)
import qualified Data.Map as M
import Data.Monoid (Monoid(..))
import Data.Maybe (fromMaybe)

-- |Knot vectors - multisets of points in a 1-dimensional space.
data Knots a = Knots !Int (M.Map a Int) deriving (Eq, Ord)

instance Show a => Show (Knots a) where
    showsPrec p ks@(Knots 1 _) = showParen (p > 10)
        ( showString "knot "
        . showsPrec 11 (head $ knots ks)
        )
    showsPrec p ks = showParen (p > 10)
        ( showString "knotsFromList "
        . showsPrec 11 (knots ks)
        )

instance (Num a, Ord a) => Monoid (Knots a) where
    mempty = Knots 0 M.empty
    mappend (Knots n1 v1) (Knots n2 v2) =
        Knots (n1 + n2) (M.filter (/=0) (M.unionWith (+) v1 v2))

instance Foldable Knots where
    foldMap f = foldMap f . knots


-- |Create a knot vector consisting of one knot.
knot :: Ord a => a -> Knots a
knot x = knotWithMultiplicity x 1

-- |Create a knot vector consisting of one knot with the specified multiplicity.
knotWithMultiplicity :: Ord a => a -> Int -> Knots a
knotWithMultiplicity k n 
    | n <= 0    = Knots 0 (M.empty)
    | otherwise = Knots n (M.singleton k n)

-- |Create a knot vector consisting of all the knots in a list.
knotsFromList :: (Ord a) => [a] -> Knots a
knotsFromList ks = knotsFromListWithMultiplicity (map (\k -> (k,1)) ks)

-- |Create a knot vector consisting of all the knots in a list.
knotsFromListWithMultiplicity :: (Ord k) => [(k, Int)] -> Knots k
knotsFromListWithMultiplicity ks = Knots (sum kMap) kMap
    where kMap = M.fromListWith (+) (filter ((>0).snd) ks)

-- |Returns the number of knots (not necessarily distinct) in a knot vector.
numKnots :: Knots t -> Int
numKnots (Knots n _) = n

-- |Returns the number of distinct knots in a knot vector.
numDistinctKnots :: Knots t -> Int
numDistinctKnots (Knots _ ks) = M.size ks

-- |Returns a list of all knots (not necessarily distinct) of a knot vector in ascending order
knots :: Knots t -> [t]
knots (Knots _ ks) = concat [replicate n k | (k,n) <- M.toAscList ks]

-- |Returns a list of all distinct knots of a knot vector in ascending order
distinctKnots :: Knots t -> [t]
distinctKnots (Knots _ ks) = M.keys ks

-- |Looks up the multiplicity of a knot (which is 0 if the point is not a knot)
knotMultiplicity :: (Ord k) => k -> Knots k -> Int
knotMultiplicity k (Knots _ ks) = fromMaybe 0 (M.lookup k ks)

setKnotMultiplicity :: Ord k => k -> Int -> Knots k -> Knots k
setKnotMultiplicity k n (Knots m ks)
    | n <= 0    = Knots (m     - n') (M.delete k ks)
    | otherwise = Knots (m + n - n') (M.insert k n ks)
    where
        n' = knotMultiplicity k (Knots m ks)

totalMultiplicity :: Knots a -> Int
totalMultiplicity kts = numKnots kts - numDistinctKnots kts

-- |@knotDomain kts p@ return the domain of a B-spline or NURBS with knot
-- vector @kts@ and degree @p@.  This is the subrange spanned by all
-- except the first and last @p@ knots.  Outside this domain, the spline
-- does not have a complete basis set.
knotDomain :: Knots a -> Int -> Maybe (a,a)
knotDomain ks@(Knots n _) p 
    | n > 2*p   = Just (head (drop p kts), head (drop p (reverse kts)))
    | otherwise = Nothing
    where
        kts = knots ks
