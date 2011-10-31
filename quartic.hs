-- Solve Polynomials of up to the fourth degree.
-- Algorithms by Ferrari, Tartaglia, Cardano, et al. (16th century Italy)

module Quartic (solvePoly) where

import Data.List (inits)

-- 'a' should be a type that supports 'sqrt (-1)'.
solvePoly :: Floating a => [a] -> [a]
solvePoly coefs
    | a == 0 = solvePoly $ init coefs
    | otherwise = solveNormalizedPoly . map (/ a) $ init coefs
    where
        a = last coefs

-- Normalized polynomials have the form of
--   x^n + a*x^(n-1) + ..
-- The coefficient for x^n is one.
-- So it gets 4 coefficients for a normalized quartic polynom.
solveNormalizedPoly :: Floating a => [a] -> [a]
solveNormalizedPoly coefs =
    map (+ shift) . solveDepressedPoly . take (degree - 1) . shiftedCoefs shift $ coefs ++ [1]
    where
        shift = -last coefs / fromIntegral degree
        degree = length coefs

shiftedCoefs :: Num a => a -> [a] -> [a]
shiftedCoefs shift coefs =
    foldl1 (zipWithDefault 0 (+)) .
    zipWith (map . (*)) coefs .
    zipWith (zipWith (*)) binomials .
    map reverse . tail . inits $ iterate (* shift) 1

zipWithDefault :: a -> (a -> a -> b) -> [a] -> [a] -> [b]
zipWithDefault _ _ [] [] = []
zipWithDefault d f xs ys =
    f (mhead xs) (mhead ys) : zipWithDefault d f (mtail xs) (mtail ys)
    where
        mhead [] = d
        mhead (x:_) = x
        mtail [] = []
        mtail (_:rest) = rest

binomials :: Num a => [[a]]
binomials =
    iterate step [1]
    where
        step prev = zipWith (+) (0 : prev) (prev ++ [0])

-- Depressed polynomials have the form of:
--   x^n + a*x^(n-2) + ..
-- The coefficient for x^n is 1 and for x^(n-1) is zero.
-- So it gets 3 coefficients for a depressed quartic polynom.
solveDepressedPoly :: Floating a => [a] -> [a]
solveDepressedPoly coefs
    | degree == 4 = solveDepressedQuartic coefs
    | degree == 3 = solveDepressedCubic coefs
    | degree == 2 = solveDepressedQuadratic coefs
    | degree == 1 = [0]
    | otherwise = error "unsupported polynomial degree"
    where
        degree = length coefs + 1

-- Based on http://en.wikipedia.org/wiki/Quartic_function#Quick_and_memorable_solution_from_first_principles
solveDepressedQuartic :: Floating a => [a] -> [a]
solveDepressedQuartic coefs =
    sols (-d/p) ++ sols (d/p)
    where
        sols t = solvePoly [c + p*p + t, 2*p, 2]
        p = sqrt . head $ solvePoly [-d*d, c*c-4*e, 2*c, 1]
        [e, d, c] = coefs

-- Based on http://en.wikipedia.org/wiki/Cubic_equation#Cardano.27s_method
--
-- Currently only provides one solution out of three.
-- Providing the other two for Complex numbers would require using cis, or some typeclass providing 'primitive roots of unity'...
solveDepressedCubic :: Floating a => [a] -> [a]
solveDepressedCubic coefs =
    [u - p/3/u]
    where
        [q, p] = coefs
        u = (-q/2 - sqrt (q*q/4 + p*p*p/27))**(1/3)

solveDepressedQuadratic :: Floating a => [a] -> [a]
solveDepressedQuadratic coefs =
    [-t, t]
    where
        t = sqrt (- head coefs)
