//------------------------------------------------------------------------------
// GB_unop:  hard-coded functions for each built-in unary operator
//------------------------------------------------------------------------------

// SuiteSparse:GraphBLAS, Timothy A. Davis, (c) 2017-2022, All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------

// If this file is in the Generated2/ folder, do not edit it
// (it is auto-generated from Generator/*).

#include "GB.h"
#ifndef GBCUDA_DEV
#include "GB_control.h"
#include "GB_atomics.h"
#include "GB_unop__include.h"

// C=unop(A) is defined by the following types and operators:

// op(A)  function:  GB (_unop_apply__identity_fc32_fp32)
// op(A') function:  GB (_unop_tran__identity_fc32_fp32)

// C type:   GxB_FC32_t
// A type:   float
// cast:     GxB_FC32_t cij = GB_cmplxf ((float) (aij), 0)
// unaryop:  cij = aij

#define GB_ATYPE \
    float

#define GB_CTYPE \
    GxB_FC32_t

// aij = Ax [pA]
#define GB_GETA(aij,Ax,pA,A_iso) \
    float aij = Ax [pA]

#define GB_CX(p) Cx [p]

// unary operator
#define GB_OP(z, x) \
    z = x ;

// casting
#define GB_CAST(z, aij) \
    GxB_FC32_t z = GB_cmplxf ((float) (aij), 0) ;

// cij = op (aij)
#define GB_CAST_OP(pC,pA)           \
{                                   \
    /* aij = Ax [pA] */             \
    float aij = Ax [pA] ;   \
    /* Cx [pC] = op (cast (aij)) */ \
    GxB_FC32_t z = GB_cmplxf ((float) (aij), 0) ;               \
    Cx [pC] = z ;        \
}

// disable this operator and use the generic case if these conditions hold
#define GB_DISABLE \
    (GxB_NO_IDENTITY || GxB_NO_FC32 || GxB_NO_FP32)

//------------------------------------------------------------------------------
// Cx = op (cast (Ax)): apply a unary operator
//------------------------------------------------------------------------------


GrB_Info GB (_unop_apply__identity_fc32_fp32)
(
    GxB_FC32_t *Cx,               // Cx and Ax may be aliased
    const float *Ax,         // A is always non-iso for this kernel
    const int8_t *restrict Ab,  // A->b if A is bitmap
    int64_t anz,
    int nthreads
)
{
    #if GB_DISABLE
    return (GrB_NO_VALUE) ;
    #else
    int64_t p ;
    if (Ab == NULL)
    { 
        #pragma omp parallel for num_threads(nthreads) schedule(static)
        for (p = 0 ; p < anz ; p++)
        {
            float aij = Ax [p] ;
            GxB_FC32_t z = GB_cmplxf ((float) (aij), 0) ;
            Cx [p] = z ;
        }
    }
    else
    { 
        // bitmap case, no transpose; A->b already memcpy'd into C->b
        #pragma omp parallel for num_threads(nthreads) schedule(static)
        for (p = 0 ; p < anz ; p++)
        {
            if (!Ab [p]) continue ;
            float aij = Ax [p] ;
            GxB_FC32_t z = GB_cmplxf ((float) (aij), 0) ;
            Cx [p] = z ;
        }
    }
    return (GrB_SUCCESS) ;
    #endif
}


//------------------------------------------------------------------------------
// C = op (cast (A')): transpose, typecast, and apply a unary operator
//------------------------------------------------------------------------------

GrB_Info GB (_unop_tran__identity_fc32_fp32)
(
    GrB_Matrix C,
    const GrB_Matrix A,
    int64_t *restrict *Workspaces,
    const int64_t *restrict A_slice,
    int nworkspaces,
    int nthreads
)
{ 
    #if GB_DISABLE
    return (GrB_NO_VALUE) ;
    #else
    #include "GB_unop_transpose.c"
    return (GrB_SUCCESS) ;
    #endif
}

#endif

