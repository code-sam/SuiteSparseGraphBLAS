function C = eps (G)
%EPS Spacing of numbers in a GraphBLAS matrix.
% C = eps (G) returns the spacing of numbers in a floating-point GraphBLAS
% matrix.
%
% See also GrB/isfloat, realmax, realmin.

% SuiteSparse:GraphBLAS, Timothy A. Davis, (c) 2017-2020, All Rights
% Reserved. http://suitesparse.com.  See GraphBLAS/Doc/License.txt.

% FUTURE: GraphBLAS should have a built-in unary operator to
% compute eps.

% convert to a MATLAB full matrix and use the MATLAB eps:

switch (GrB.type (G))

    case { 'single' }
        C = GrB (eps (single (full (G)))) ;

    case { 'double' }
        C = GrB (eps (double (full (G)))) ;

    case { 'single complex', 'double complex' }
        C = max (eps (real (G)), eps (imag (G))) ;

    otherwise
        gb_error ('input must be floating-point') ;

end

