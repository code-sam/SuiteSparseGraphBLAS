function C = bitcmp (A, assumedtype)
%BITCMP bitwise complement.
% C = bitcmp (A) computes the bitwise complement of A.  C is a full
% matrix.  To complement all the bits in the entries of a sparse matrix,
% but not the implicit entries not in the pattern of C, use
% C = GrB.apply ('bitcmp', A) instead.
%
% With a second parameter, C = bitcmp (A,assumedtype) provides a data type
% to convert A to if it a floating-point type.  If A already has an
% integer type, then it are not modified.  Otherwise, A is converted to
% assumedtype, which can be 'int8', 'int16', 'int32', 'int64', 'uint8',
% 'uint16', 'uint32' or 'uint64'.  The default is 'uint64'.
%
% The input matrix must be real, and can only be a GraphBLAS matrix.  This
% is an overloaded method, and the MATLAB built-in bitcmp is used if A is
% a MATLAB matrix.  C is returned as a GraphBLAS matrix, as the same type
% as A after conversion to assumedtype, if needed.
%
% Example:
%
%   A = GrB (magic (4), 'uint8')
%   C = bitcmp (A)
%   fprintf ('\nA: ') ; fprintf ('%3x ', A) ; fprintf ('\n') ;
%   fprintf ('\nC: ') ; fprintf ('%3x ', C) ; fprintf ('\n') ;
%   % in MATLAB:
%   C2 = bitcmp (uint8 (A))
%   assert (all (C2 == C, 'all'))
%
% See also GrB/bitor, GrB/bitand, GrB/bitxor, GrB/bitshift, GrB/bitget,
% GrB/bitset, GrB/bitclr.

% SuiteSparse:GraphBLAS, Timothy A. Davis, (c) 2017-2020, All Rights
% Reserved. http://suitesparse.com.  See GraphBLAS/Doc/License.txt.

if (nargin < 2)
    assumedtype = 'uint64' ;
end

if (isobject (A))
    A = A.opaque ;
end

atype = gbtype (A) ;

if (contains (atype, 'complex'))
    gb_error ('inputs must be real') ;
end

if (isequal (atype, 'logical'))
    gb_error ('inputs must not be logical') ;
end

if (~contains (assumedtype, 'int'))
    gb_error ('assumedtype must be an integer type') ;
end

% C will have the same type as A on input
ctype = atype ;

if (isequal (atype, 'double') || isequal (atype, 'single'))
    A = gbnew (A, assumedtype) ;
end

C = GrB (gbapply ('bitcmp', gbfull (A)), ctype) ;

