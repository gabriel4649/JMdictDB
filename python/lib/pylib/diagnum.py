# Diagonal indexing functions (Stuart McGraw, 2018)
# Given an integer x,y regtangular coordinate, xy2d(x,y) will return
# a "diagonal index" calculated by numbering grid points sequentially
# starting at the origin and preceeding down the x-axis numbering
# each point on each diagonal (x,0):(0,x) in turn.  Illustration:
#
#      X: 0    1    2    3    4    5    6    7
#    Y +---------------------------------------
#    0 |  0    1    3    6   10   15   21   28
#    1 |  2    4    7   11   16   22   29   37
#    2 |  5    8   12   17   23   30   38   47
#    3 |  9   13   18   24   31   39   48   58
#    4 | 14   19   25   32   40   49   59   70
#    5 | 20   26   33   41   50   60   71   83
#    6 | 27   34   42   51   61   72   84   97
#    7 | 35   43   52   62   73   85   98  112
#
# d2xy(d) performs the inverse calculation, returning x,y given a 
# diagonal number.
#
# The values along the x-axis for y==0 are the "triangular number
# series" given by the formula: (x * (x+1)) / 2.
# To perform the inverse transform one has to find the largest 
# triangular number less than or equal to the given diagonal number.
# The formula for this is directly derived by applying the quadratic
# formula to the (quadratic) equation for triangular numbers shown
# above.
# 
# Note that the calculations in xy2d() and d2xy() are careful to use
# only integer calculations.  If the calculations are done naively
# using Python's divide operator ('/') and math.sqrt function,
# floating point values will be introduced.  Since Python's floating
# point calculations have an effective precision of 53 bits, values
# of d > ~2**53 == ~4e15 may produce in erroneous results which
# limits x and y to the square root of that or ~6e7.

def xy2d (x, y):
          # We need to calculate t=(xs*(xs+1))/2 but can't use that 
          # expression because for large xs the Python divide operator
          # will return a floating point value.  divmod() will return
          # integer values for integer arguments.
        xs = x + y;  t, r = divmod (xs * (xs+1), 2)
        #assert r == 0   # xs*(xs+1) will always be even so there
                         #  will never be a remainder.
        return t + y

def d2xy (d):
          # The inverse function requires finding the largest triangular
          # number less than or equal to 'd'.  The formula for this is
          # is derived by applying the quadratic formula to the equation
          # for triangular numbers above: 
          #   floor(sqrt(8*d-1)/2 - 1) 
          # We can't use math.sqrt or Python divide because of limited
          # precision of floating-point results.  As with xy2d() the
          # calculations are done strictly with integers.
        t, r = divmod (isqrt (8 * d + 1) - 1,  2)
        y = d - xy2d (t, 0)
        return t-y, y

def isqrt(x):
          # Source:
          # http://code.activestate.com/recipes/577821-integer-square-root-function/
        if x < 0: raise ValueError('argument must be >= 0')
        n = int(x)
        if n == 0: return 0
        a, b = divmod(n.bit_length(), 2)
        x = 2**(a+b)
        while True:
            y = (x + n//x)//2
            if y >= x: return x
            x = y
