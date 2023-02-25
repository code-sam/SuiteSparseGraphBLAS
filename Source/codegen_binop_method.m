function codegen_binop_method (binop, op, xtype)
%CODEGEN_BINOP_METHOD create a function to compute C=binop(A,B)
%
% codegen_binop_method (binop, op, xtype)

% SuiteSparse:GraphBLAS, Timothy A. Davis, (c) 2017-2022, All Rights Reserved.
% SPDX-License-Identifier: Apache-2.0

f = fopen ('control.m4', 'w') ;
fprintf (f, 'm4_divert(-1)\n') ;

% no code is generated for the ANY operator (SECOND is used in its place)
assert (~isequal (binop, 'any')) ;

[fname, unsigned, bits] = codegen_type (xtype) ;

name = sprintf ('%s_%s', binop, fname) ;

% function names
fprintf (f, 'm4_define(`_AaddB'', `_AaddB__%s'')\n', name) ;
fprintf (f, 'm4_define(`_Cdense_accumB'', `_Cdense_accumB__%s'')\n', name) ;
fprintf (f, 'm4_define(`_Cdense_accumb'', `_Cdense_accumb__%s'')\n', name) ;
fprintf (f, 'm4_define(`_Cdense_ewise3_noaccum'', `_Cdense_ewise3_noaccum__%s'')\n', name) ;

% subset of operators for GB_dense_ewise3_accum
switch (binop)
    case { 'min', 'max', 'plus', 'minus', 'rminus', 'times', 'div', 'rdiv' }
        % these operators are used in ewise3_accum
        fprintf (f, 'm4_define(`_Cdense_ewise3_accum'', `_Cdense_ewise3_accum__%s'')\n', name) ;
        fprintf (f, 'm4_define(`if_is_binop_subset'', `0'')\n') ;
    otherwise
        % disable GB_dense_ewise3_accum
        fprintf (f, 'm4_define(`_Cdense_ewise3_accum'', `(none)'')\n') ;
        fprintf (f, 'm4_define(`if_is_binop_subset'', `-1'')\n') ;
end

% subset of operators for GB_rowscale and GB_colscale
switch (binop)
    case { 'min', 'max', 'plus', 'minus', 'rminus', 'times', 'div', 'rdiv', ...
        'first', 'second', 'isgt', 'islt', 'isge', 'isle', ...
        'gt', 'lt', 'ge', 'le', 'lor', 'land', 'lxor' }
        % these operators are used in GB_AxB_*scale
        binop_is_semiring_multiplier = true ;
    case { 'eq', 'iseq', 'ne', 'isne' }
        % these do not appear in complex semirings
        binop_is_semiring_multiplier = (~codegen_contains (xtype, 'FC')) ;
    case { 'bor', 'band', 'bxor', 'bxnor' }
        % these operators are used in GB_AxB_*scale for uint* only
        binop_is_semiring_multiplier = codegen_contains (xtype, 'uint') ;
    otherwise
        % these operators are not used in GB_AxB_*scale by any builtin semiring
        binop_is_semiring_multiplier = false ;
end
if (binop_is_semiring_multiplier)
    % enable rowscale and colscale
    fprintf (f, 'm4_define(`_AxD'', `_AxD__%s'')\n', name) ;
    fprintf (f, 'm4_define(`_DxB'', `_DxB__%s'')\n', name) ;
    fprintf (f, 'm4_define(`if_binop_is_semiring_multiplier'', `0'')\n') ;
else
    % disable rowscale and colscale
    fprintf (f, 'm4_define(`_AxD'', `(none)'')\n') ;
    fprintf (f, 'm4_define(`_DxB'', `(none)'')\n') ;
    fprintf (f, 'm4_define(`if_binop_is_semiring_multiplier'', `-1'')\n') ;
end

% subset of operators for GB_apply
switch (binop)
    case { 'first', 'second', 'any', 'pair' }
        % disable bind1st or bind2nd for these operators
        fprintf (f, 'm4_define(`_bind1st'', `(none)'')\n', name) ;
        fprintf (f, 'm4_define(`_bind1st_tran'', `(none)'')\n', name) ;
        fprintf (f, 'm4_define(`_bind2nd'', `(none)'')\n', name) ;
        fprintf (f, 'm4_define(`_bind2nd_tran'', `(none)'')\n', name) ;
        fprintf (f, 'm4_define(`if_binop_bind_is_enabled'', `-1'')\n') ;
    otherwise
        % enable bind1st and bind2nd
        fprintf (f, 'm4_define(`_bind1st'', `_bind1st__%s'')\n', name) ;
        fprintf (f, 'm4_define(`_bind1st_tran'', `_bind1st_tran__%s'')\n', name) ;
        fprintf (f, 'm4_define(`_bind2nd'', `_bind2nd__%s'')\n', name) ;
        fprintf (f, 'm4_define(`_bind2nd_tran'', `_bind2nd_tran__%s'')\n', name) ;
        fprintf (f, 'm4_define(`if_binop_bind_is_enabled'', `0'')\n') ;
end

% subset of operators for GB_emult
switch (binop)
    case { 'pair' }
        % disable emult for these operators
        fprintf (f, 'm4_define(`_AemultB'', `(none)'')\n') ;
        fprintf (f, 'm4_define(`_AemultB_02'', `(none)'')\n') ;
        fprintf (f, 'm4_define(`_AemultB_04'', `(none)'')\n') ;
        fprintf (f, 'm4_define(`_AemultB_bitmap'', `(none)'')\n') ;
        fprintf (f, 'm4_define(`if_binop_emult_is_enabled'', `-1'')\n') ;
    otherwise
        % enable emult for these operators
        fprintf (f, 'm4_define(`_AemultB'', `_AemultB__%s'')\n', name) ;
        fprintf (f, 'm4_define(`_AemultB_02'', `_AemultB_02__%s'')\n', name) ;
        fprintf (f, 'm4_define(`_AemultB_04'', `_AemultB_04__%s'')\n', name) ;
        fprintf (f, 'm4_define(`_AemultB_bitmap'', `_AemultB_bitmap__%s'')\n', name) ;
        fprintf (f, 'm4_define(`if_binop_emult_is_enabled'', `0'')\n') ;
end

if (isequal (binop, 'second'))
    fprintf (f, 'm4_define(`GB_op_is_second'', `#define GB_OP_IS_SECOND 1'')\n') ;
else
    fprintf (f, 'm4_define(`GB_op_is_second'', `'')\n') ;
end

% determine type of z, x, and y from xtype and binop
switch (binop)
    case { 'eq', 'ne', 'gt', 'lt', 'ge', 'le' }
        % GrB_LT_* and related operators are TxT -> bool
        ztype = 'bool' ;
        ytype = xtype ;
    case { 'cmplx' }
        % GxB_CMPLX_* are TxT -> (complex T)
        if (isequal (xtype, 'float'))
            ztype = 'GxB_FC32_t' ;
        else
            ztype = 'GxB_FC64_t' ;
        end
        ytype = xtype ;
    case { 'bshift' }
        % z = bitshift (x,y): y is always int8
        ztype = xtype ;
        ytype = 'int8_t' ;
    otherwise
        % all other operators: z, x, and y have the same type
        ztype = xtype ;
        ytype = xtype ;
end

fprintf (f, 'm4_define(`GB_ztype'',  `#define GB_Z_TYPE %s'')\n', ztype) ;
fprintf (f, 'm4_define(`GB_ctype'',  `#define GB_C_TYPE %s'')\n', ztype) ;

if (isequal (xtype, ytype))
    fprintf (f, 'm4_define(`GB_atype_is_btype'', `'')\n') ;
else
    fprintf (f, 'm4_define(`GB_atype_is_btype'', `#define GB_ATYPE_IS_BTYPE 0'')\n') ;
end
if (isequal (ztype, xtype))
    fprintf (f, 'm4_define(`GB_ctype_is_atype'', `'')\n') ;
else
    fprintf (f, 'm4_define(`GB_ctype_is_atype'', `#define GB_CTYPE_IS_ATYPE 0'')\n') ;
end
if (isequal (ztype, ytype))
    fprintf (f, 'm4_define(`GB_ctype_is_btype'', `'')\n') ;
else
    fprintf (f, 'm4_define(`GB_ctype_is_btype'', `#define GB_CTYPE_IS_BTYPE 0'')\n') ;
end

% C_dense_update: operators z=f(x,y) where ztype and xtype match, and binop is not 'first'
if (isequal (xtype, ztype) && ~isequal (binop, 'first'))
    % enable C dense update
    fprintf (f, 'm4_define(`if_C_dense_update'', `0'')\n') ;
else
    % disable C dense update
    fprintf (f, 'm4_define(`if_C_dense_update'', `-1'')\n') ;
end

% to get an entry from A
fprintf (f, 'm4_define(`GB_atype'',  `#define GB_A_TYPE %s'')\n', xtype) ;
fprintf (f, 'm4_define(`GB_a2type'', `#define GB_A2TYPE %s'')\n', xtype) ;
if (isequal (binop, 'second') || isequal (binop, 'pair'))
    % value of A is ignored for the SECOND, PAIR, and positional operators
    fprintf (f, 'm4_define(`GB_a_is_pattern'', `#define GB_A_IS_PATTERN 1'')\n') ;
    gb_geta = '' ;
else
    fprintf (f, 'm4_define(`GB_a_is_pattern'', `#define GB_A_IS_PATTERN 0'')\n') ;
    gb_geta = ' aij = Ax [(A_iso) ? 0 : (pA)]' ;
end
gb_declarea = sprintf (' %s aij', xtype) ;
fprintf (f, 'm4_define(`GB_geta'', `#define GB_GETA(aij,Ax,pA,A_iso)%s'')\n', gb_geta) ;
fprintf (f, 'm4_define(`GB_declarea'', `#define GB_DECLAREA(aij)%s'')\n', gb_declarea) ;

% to get an entry from B
fprintf (f, 'm4_define(`GB_btype'',  `#define GB_B_TYPE %s'')\n', ytype) ;
fprintf (f, 'm4_define(`GB_b2type'', `#define GB_B2TYPE %s'')\n', ytype) ;
if (isequal (binop, 'first') || isequal (binop, 'pair'))
    % value of B is ignored for the FIRST, PAIR, and positional operators
    fprintf (f, 'm4_define(`GB_b_is_pattern'', `#define GB_B_IS_PATTERN 1'')\n') ;
    gb_getb = '' ;
else
    fprintf (f, 'm4_define(`GB_b_is_pattern'', `#define GB_B_IS_PATTERN 0'')\n') ;
    gb_getb = ' bij = Bx [(B_iso) ? 0 : (pB)]' ;
end
gb_declareb = sprintf (' %s bij', ytype) ;
fprintf (f, 'm4_define(`GB_getb'', `#define GB_GETB(bij,Bx,pB,B_iso)%s'')\n', gb_getb) ;
fprintf (f, 'm4_define(`GB_declareb'', `#define GB_DECLAREB(bij)%s'')\n', gb_declareb) ;

% to copy an entry from A to C
if (isequal (xtype, 'GxB_FC32_t') && isequal (ztype, 'bool'))
    a2c = '(crealf (Ax [(A_iso) ? 0 : (pA)]) != 0) || (cimagf (Ax [(A_iso) ? 0 : (pA)]) != 0)' ;
elseif (isequal (xtype, 'GxB_FC64_t') && isequal (ztype, 'bool'))
    a2c = '(creal (Ax [(A_iso) ? 0 : (pA)]) != 0) || (cimag (Ax [(A_iso) ? 0 : (pA)]) != 0)' ;
elseif (isequal (xtype, 'float') && isequal (ztype, 'GxB_FC32_t'))
    a2c = 'GB_CMPLX32 (Ax [(A_iso) ? 0 : (pA)], 0)' ;
elseif (isequal (xtype, 'double') && isequal (ztype, 'GxB_FC64_t'))
    a2c = 'GB_CMPLX64 (Ax [(A_iso) ? 0 : (pA)], 0)' ;
else
    a2c = '' ;
end
if (isempty (a2c))
    fprintf (f, 'm4_define(`GB_copy_a_to_c'', `'')\n') ;
else
    fprintf (f, 'm4_define(`GB_copy_a_to_c'', `#define GB_COPY_A_TO_C(Cx,pC,Ax,pA,A_iso) Cx [pC] = %s'')\n', a2c) ;
end

% to copy an entry from B to C
if (isequal (ytype, 'GxB_FC32_t') && isequal (ztype, 'bool'))
    b2c = '(crealf (Bx [(B_iso) ? 0 : (pB)]) != 0) || (cimagf (Bx [(B_iso) ? 0 : (pB)]) != 0)' ;
elseif (isequal (ytype, 'GxB_FC64_t') && isequal (ztype, 'bool'))
    b2c = '(creal (Bx [(B_iso) ? 0 : (pB)]) != 0) || (cimag (Bx [(B_iso) ? 0 : (pB)]) != 0)' ;
elseif (isequal (ytype, 'float') && isequal (ztype, 'GxB_FC32_t'))
    b2c = 'GB_CMPLX32 (Bx [(B_iso) ? 0 : (pB)], 0)' ;
elseif (isequal (ytype, 'double') && isequal (ztype, 'GxB_FC64_t'))
    b2c = 'GB_CMPLX64 (Bx [(B_iso) ? 0 : (pB)], 0)' ;
else
    b2c = '' ;
end
if (isempty (b2c))
    fprintf (f, 'm4_define(`GB_copy_b_to_c'', `'')\n') ;
else
    fprintf (f, 'm4_define(`GB_copy_b_to_c'', `#define GB_COPY_B_TO_C(Cx,pC,Bx,pB,B_iso) Cx [pC] = %s'')\n', b2c) ;
end

% type-specific idiv
if (~isempty (strfind (op, 'idiv')))
    if (unsigned)
        op = strrep (op, 'idiv', sprintf ('idiv_uint%d', bits)) ;
    else
        op = strrep (op, 'idiv', sprintf ('idiv_int%d', bits)) ;
    end
end

% create the binary operator
op = strrep (op, 'xarg', 'x') ;
op = strrep (op, 'yarg', 'y') ;
fprintf (f, 'm4_define(`GB_binaryop'', `#define GB_BINOP(z,x,y,i,j) z = %s'')\n', op) ;

% handle non-commutative operators
switch (binop)
    case { 'pair' }
        fprintf (f, 'm4_define(`binop_not_commutative'', `-1'')\n') ;
        fprintf (f, 'm4_define(`binop_commutative'',     `-1'')\n') ;
    case { 'pow', 'bget', 'bset', 'bclr', 'bshift', 'atan2', 'fmod', ...
        'remainder', 'copysign', 'ldexp', 'cmplx' }
        % these operators are not commutative
        fprintf (f, 'm4_define(`binop_not_commutative'', `0'')\n') ;
        fprintf (f, 'm4_define(`binop_commutative'',     `-1'')\n') ;
    otherwise
        % these operators are not commutative
        fprintf (f, 'm4_define(`binop_not_commutative'', `-1'')\n') ;
        fprintf (f, 'm4_define(`binop_commutative'',     `0'')\n') ;
end

% create the disable flag
disable = sprintf ('GxB_NO_%s', upper (binop)) ;
disable = [disable (sprintf (' || GxB_NO_%s', upper (fname)))] ;
disable = [disable (sprintf (' || GxB_NO_%s_%s', upper (binop), upper (fname)))] ;
if (isequal (ytype, 'GxB_FC32_t') && ...
    (isequal (binop, 'first') || isequal (binop, 'second')))
    % disable the FIRST_FC32 and SECOND_FC32 binary operators for
    % MS Visual Studio 2019.  These files trigger a bug in the compiler.
    disable = [disable ' || GB_COMPILER_MSC_2019_OR_NEWER'] ;
end
fprintf (f, 'm4_define(`GB_disable'', `(%s)'')\n', disable) ;

% ff = fopen ('temp.h', 'a') ;
% fprintf (ff, '// #define GxB_NO_%s_%s\n',  upper (binop), upper (fname)) ;
% fclose (ff) ;

fprintf (f, 'm4_divert(0)\n') ;
fclose (f) ;

% construct the *.c file
cmd = sprintf ('cat control.m4 Generator/GB_binop.c | m4 -P | awk -f codegen_blank.awk > Generated2/GB_binop__%s.c', name) ;
fprintf ('.') ;
system (cmd) ;

% append to the *.h file
system ('cat control.m4 Generator/GB_binop.h | m4 -P | awk -f codegen_blank.awk | grep -v SPDX >> Generated2/GB_binop__include.h') ;

delete ('control.m4') ;

