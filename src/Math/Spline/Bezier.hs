{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances, UndecidableInstances #-}
module Math.Spline.Bezier
    ( Bezier, bezier, splitBezier
    ) where

import Math.Spline.BSpline
import Math.Spline.Class
import Math.Spline.Knots

import Control.Applicative
import Data.VectorSpace

data Bezier v = Bezier !Int [v] deriving (Eq, Ord)

bezier :: [v] -> Bezier v
bezier cs
    | null cs   = error "bezier: no control points given"
    | otherwise = Bezier (length cs - 1) cs

instance Show v => Show (Bezier v) where
    showsPrec p (Bezier _ cs) = showParen (p>10)
        ( showString "bezier "
        . showsPrec 11 cs
        )

instance (VectorSpace v, Fractional (Scalar v), Ord (Scalar v)) => Spline Bezier v where
    splineDomain (Bezier _  _) = Just (0,1)
    evalSpline   (Bezier _ cs) = head . last . deCasteljau cs
    splineDegree (Bezier p  _) = p
    knotVector   (Bezier p  _) = knotsFromListWithMultiplicity [(0, p+1), (1, p+1)]
    toBSpline = bSpline <$> knotVector <*> controlPoints

instance Spline Bezier v => ControlPoints Bezier v where
    controlPoints (Bezier _ cs) = cs

deCasteljau :: VectorSpace v => [v] -> Scalar v -> [[v]]
deCasteljau [] t = []
deCasteljau cs t = cs : deCasteljau (zipWith interp cs (tail cs)) t
    where
        interp x0 x1 = lerp x0 x1 t

splitBezier :: VectorSpace v => Bezier v -> Scalar v -> (Bezier v, Bezier v)
splitBezier (Bezier n cs) t = 
    ( Bezier n (map head css)
    , Bezier n (reverse (map last css))
    ) where css = deCasteljau cs t
