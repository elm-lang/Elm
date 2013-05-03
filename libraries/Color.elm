
module Color where

data Color = Color Int Int Int Float

-- Create RGB colors with an alpha component for transparency.
-- The alpha component is specified with numbers between 0 and 1.
rgba : Int -> Int -> Int -> Float -> Color
rgba = Color

-- Create RGB colors from numbers between 0 and 255 inclusive.
rgb : Int -> Int -> Int -> Color
rgb r g b = Color r g b 1

red  : Color
red  = Color 255  0   0  1
lime : Color
lime = Color  0  255  0  1
blue : Color
blue = Color  0   0  255 1

yellow  : Color
yellow  = Color 255 255  0  1
cyan    : Color
cyan    = Color  0  255 255 1
magenta : Color
magenta = Color 255  0  255 1

black : Color
black = Color  0   0   0  1
white : Color
white = Color 255 255 255 1

gray : Color
gray = Color 128 128 128 1
grey : Color
grey = Color 128 128 128 1

maroon : Color
maroon = Color 128  0   0  1
navy   : Color
navy   = Color  0   0  128 1
green  : Color
green  = Color  0  128  0  1

teal   : Color
teal   = Color  0  128 128 1
purple : Color
purple = Color 128  0  128 1

violet : Color
violet = Color 238 130 238 1
forestGreen : Color
forestGreen = Color 34 139 34 1

-- Produce a &ldquo;complementary color&rdquo;.
-- The two colors will accent each other.
complement : Color -> Color

-- Create HSV colors with an alpha component for transparency.
-- The alpha component is specified with numbers between 0 and 1.
hsva : Int -> Float -> Float -> Float -> Color

-- Create HSV colors. HSV stands for hue-saturation-value.
--
-- Hue is a degree from 0 to 360 representing a color wheel: red at 0&deg;,
-- green at 120&deg;, blue at 240&deg;, and red again at 360&deg;.
-- This makes it easy to cycle through colors and compute color complements,
-- triads, tetrads, etc.
--
-- Saturation is a number between 1 and 0 where lowering this number makes
-- your color more grey. This can help you tone a color down.
--
-- Value is also a number between 1 and 0. Lowering this number makes your
-- color more black.
--
-- Look up the &ldquo;HSV cylinder&rdquo; for more information.
hsv : Int -> Float -> Float -> Color

data Gradient
  = Linear (Float,Float) (Float,Float) [(Float,Color)]
  | Radial (Float,Float) Float (Float,Float) Float [(Float,Color)]

linear : (Number a, Number a) ->
         (Number a, Number a) -> [(Float,Color)] -> Gradient
linear = Linear
radial : (Number a,Number a) -> Number a ->
         (Number a,Number a) -> Number a -> [(Float,Color)] -> Gradient
radial = Radial
