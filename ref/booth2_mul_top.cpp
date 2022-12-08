// ****************************************************
// ****************************************************
// ****************************************************
// Algorithm for MSB-first Multiplication in GF(2^m)
// 
// Input : A(x), B(x)
// Output : P(x) = A(x)B(x)
// 
// ****************************************************
// ****************************************************
// ****************************************************

#include <iostream>
#include <cstring>
#include <cmath>
#include <ctime>
#include <random>

#define MUL_IN_WD 32
#define MUL_OUT_WD 64
#define TEST_NUM 1000

// positive A * positive B is ok
// negative A * positive B is ok
// !!! positive A * negative B is ok
// !!! negative A * negative B is ok
// 4 bit carry look ahead adder
#define BASIC_ADDER_WD 4
void adder_carry_look_ahead_4bit( bool Ai[BASIC_ADDER_WD] , bool Bi[BASIC_ADDER_WD] , bool Cin , bool So[BASIC_ADDER_WD] , bool & Cout )
{
    bool wireC[BASIC_ADDER_WD] ;
    bool wireP[BASIC_ADDER_WD] ;
    bool wireG[BASIC_ADDER_WD] ;
    memset( wireC , 0 , sizeof(bool) * BASIC_ADDER_WD ) ;
    memset( wireP , 0 , sizeof(bool) * BASIC_ADDER_WD ) ;
    memset( wireG , 0 , sizeof(bool) * BASIC_ADDER_WD ) ;

    for( int i = 0 ; i < BASIC_ADDER_WD ; i++ )
    {
        wireP[i] = Ai[i] | Bi[i] ;
        wireG[i] = Ai[i] & Bi[i] ;
    }

    wireC[0] = wireG[0]                                            \
             | ( Cin & wireP[0] )                                  ;
    wireC[1] = wireG[1]                                            \
             | ( wireG[0] & wireP[1] )                             \
             | ( Cin & wireP[0] & wireP[1] )                       ;
    wireC[2] = wireG[2]                                            \
             | ( wireG[1] & wireP[2] )                             \
             | ( wireG[0] & wireP[1] * wireP[2] )                  \
             | ( Cin & wireP[0] & wireP[1] & wireP[2] )            ;
    wireC[3] = wireG[3]                                            \
             | ( wireG[2] & wireP[3] )                             \
             | ( wireG[1] & wireP[2] & wireP[3] )                  \
             | ( wireG[0] & wireP[1] & wireP[2] & wireP[3] )       \
             | ( Cin & wireP[0] & wireP[1] & wireP[2] & wireP[3] ) ;
    
    So[0] = Ai[0] ^ Bi[0] ^ Cin      ;
    So[1] = Ai[1] ^ Bi[1] ^ wireC[0] ;
    So[2] = Ai[2] ^ Bi[2] ^ wireC[1] ;
    So[3] = Ai[3] ^ Bi[3] ^ wireC[2] ;
    
    Cout = wireC[3] ;

    return ;
}

// 16 bit carry look ahead adder
#define PIPLINE_ADDER_WD 16
void adder_carry_look_ahead_16bit( bool Ai[PIPLINE_ADDER_WD] , bool Bi[PIPLINE_ADDER_WD] , bool Cin , bool So[PIPLINE_ADDER_WD] , bool & Cout )
{
    bool wireC[BASIC_ADDER_WD + 1] ; // one more bit to store Cin , C[0] = Cin
    memset( wireC , 0 , sizeof(bool) * ( BASIC_ADDER_WD + 1 ) ) ;
    wireC[0] = Cin ;

    for( int i = 0 ; i < PIPLINE_ADDER_WD / BASIC_ADDER_WD ; i++ )
    {
        adder_carry_look_ahead_4bit( Ai + BASIC_ADDER_WD * i , Bi + BASIC_ADDER_WD * i , wireC[i] , So + BASIC_ADDER_WD * i , wireC[i + 1] ) ;
    }

    Cout = wireC[BASIC_ADDER_WD] ;
    return ;
}

// 3-2 adder
void three_two_adder( bool X1i , bool X2i , bool X3i , bool & So , bool & Carry )
{
    bool xor1 = X1i ^ X2i ;
    So = xor1 ^ X3i ;
    Carry = ( xor1 & X3i ) | ( !xor1 & X1i ) ;
    return ;
}

// 4-2 compressor
void four_two_compressor( bool X1i , bool X2i , bool X3i , bool X4i , bool Ci , bool & So , bool & Co , bool & Carry )
{
    bool wireSum = 0 ;
    three_two_adder( X1i , X2i , X3i , wireSum , Carry ) ;
    three_two_adder( wireSum , X4i , Ci , So , Co ) ;
    return ; 
}

// booth2 generate one partial product
#define BOOTH2_PP_TRA_WD 3
void booth2_one_pp_generator( bool Ai[MUL_IN_WD] , bool Bi[BOOTH2_PP_TRA_WD] , bool PPo[MUL_IN_WD + 1] , bool & So , bool & Eo )
{
    bool wireSo = 0 ;
    wireSo = Bi[BOOTH2_PP_TRA_WD - 1] ;

    int wireSumBi = 0 ;
    for( int i = BOOTH2_PP_TRA_WD - 1 ; i > -1 ; i-- )
    {
        wireSumBi = wireSumBi << 1 ;
        wireSumBi += Bi[i] ;
    }

    bool wirePPo[MUL_IN_WD + 1] ;
    memset( wirePPo , 0 , sizeof(bool) * ( MUL_IN_WD + 1 ) ) ;
    bool wireEo = 0 ;
    switch ( wireSumBi )
    {
    case 0 : memset( wirePPo , 0 , sizeof(bool) * ( MUL_IN_WD + 1 ) ) ;
             wireEo = 1 ;
             break ;
    case 1 : 
    case 2 : memcpy( wirePPo , Ai , sizeof(bool) * MUL_IN_WD ) ; wirePPo[MUL_IN_WD] = Ai[MUL_IN_WD - 1] ;
             wireEo = !Ai[MUL_IN_WD - 1] ;
             break ;
    case 3 : memcpy( wirePPo + 1 , Ai , sizeof(bool) * MUL_IN_WD ) ; wirePPo[0] = 0 ;
             wireEo = !Ai[MUL_IN_WD - 1] ;
             break ;
    case 4 : memcpy( wirePPo + 1 , Ai , sizeof(bool) * MUL_IN_WD ) ; wirePPo[0] = 0 ;
             for( int i = 0 ; i < MUL_IN_WD + 1 ; i++ )
                wirePPo[i] = !wirePPo[i] ;
             wireEo = Ai[MUL_IN_WD - 1] ;
             break ;
    case 5 : 
    case 6 : memcpy( wirePPo , Ai , sizeof(bool) * MUL_IN_WD ) ; wirePPo[MUL_IN_WD] = Ai[MUL_IN_WD - 1] ;
             for( int i = 0 ; i < MUL_IN_WD + 1 ; i++ )
                wirePPo[i] = !wirePPo[i] ; 
             wireEo = Ai[MUL_IN_WD - 1] ;
             break ; 
    case 7 : memset( wirePPo , 1 , sizeof(bool) * ( MUL_IN_WD + 1 ) ) ;
             wireEo = 0 ;
             break ;
    default: memset( wirePPo , 0 , sizeof(bool) * ( MUL_IN_WD + 1 ) ) ;
             wireEo = 1 ;
             break ;
    }
    
    memcpy( PPo , wirePPo , sizeof(bool) * ( MUL_IN_WD + 1 ) ) ;
    Eo = wireEo ;
    So = wireSo ;
    return ;
}

// booth2 generate all partial product
#define BOOTH2_PP_TRA_NUM MUL_IN_WD / ( BOOTH2_PP_TRA_WD - 1 )
void booth2_all_pp_generator( bool Ai[MUL_IN_WD] , bool Bi[MUL_IN_WD] , bool PPo[BOOTH2_PP_TRA_NUM][MUL_IN_WD + 1] , bool So[BOOTH2_PP_TRA_NUM] , bool Eo[BOOTH2_PP_TRA_NUM] )
{
    bool padBi[MUL_IN_WD + 1] ;
    memset( padBi , 0 , sizeof(bool) * ( MUL_IN_WD + 1 ) ) ;
    memcpy( padBi + 1 , Bi , MUL_IN_WD ) ;
    for(int i = 0 ; i < BOOTH2_PP_TRA_NUM ; i++ )
    {
        booth2_one_pp_generator( Ai , padBi + i * (BOOTH2_PP_TRA_WD - 1) , PPo[i] , So[i] , Eo[i] ) ;
    }
    return ;
}

// binary tree compressor
// stage 1 : PP0 PP1 PP2 PP3 | PP4 PP5 PP6 PP7 | PP8 PP9 PP10 PP11 | PP12 PP13 PP14 PP15
// stage 2 :  SO0_s1  CO0_s1    SO1_s1  CO1_s1 |   SO2_s1  CO2_s1      SO3_s1   CO3_s1
// stage 3 :      SO0_s2            CO0_s2            SO1_s2               CO1_s2
// result  :                          SO0_s3         CO0_s3     
void binary_tree_compressor_array( bool PPi[BOOTH2_PP_TRA_NUM][MUL_IN_WD + 1] , bool Si[BOOTH2_PP_TRA_NUM] , bool Ei[BOOTH2_PP_TRA_NUM] , bool So[MUL_OUT_WD] , bool Co[MUL_OUT_WD] )
{

    // BEGIN OF STAGE 1
    const int COM_IN_NUM    = 4 ;
    const int PAD_SIGN_WD   = 2 ;
    const int STAGE_1_PP0T3_IN_WD = ( MUL_IN_WD + 1 ) + ( (COM_IN_NUM - 1) * (BOOTH2_PP_TRA_WD - 1) ) + PAD_SIGN_WD ;

    bool PP0to3S1[COM_IN_NUM][STAGE_1_PP0T3_IN_WD] ;
    memset( PP0to3S1 , 0 , sizeof(bool) * COM_IN_NUM * STAGE_1_PP0T3_IN_WD ) ;
    bool SO0to3S1[STAGE_1_PP0T3_IN_WD] ;
    bool CO0to3S1[STAGE_1_PP0T3_IN_WD] ;
    bool CA0to3S1[STAGE_1_PP0T3_IN_WD + 1] ; CA0to3S1[0] = 0 ; // one more bit , least bit for cin input 
    // padding sign bit for PP0to3S1
    {
        // PP0to3S1[0] = { 5'b0, Ei[0], !Ei[0], !Ei[0], PPi[0] }
    memcpy( PP0to3S1[0]                 , PPi[0] , sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP0to3S1[0] + MUL_IN_WD + 1 , !Ei[0] , sizeof(bool) * 2                ) ;
    memset( PP0to3S1[0] + MUL_IN_WD + 3 , Ei[0]  , sizeof(bool) * 1                ) ;
    memset( PP0to3S1[0] + MUL_IN_WD + 4 , 0      , sizeof(bool) * 5                ) ;
        // PP0to3S1[1] = { 4'b0, 1'b1, Ei[1], PPi[1], 1'b0, Si[0] }
    memset( PP0to3S1[1]                 , Si[0]   , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[1] + 1             , 0       , sizeof(bool) * 1               ) ;
    memcpy( PP0to3S1[1] + 2             , PPi[1]  , sizeof(bool) * (MUL_IN_WD + 1) ) ;
    memset( PP0to3S1[1] + MUL_IN_WD + 3 , Ei[1]   , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[1] + MUL_IN_WD + 4 , 1       , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[1] + MUL_IN_WD + 5 , 0       , sizeof(bool) * 4               ) ;
        // PP0to3S1[2] = { 2'b0, 1'b1, Ei[2], PPi[2], 1'b0, Si[1], 2'b0 }
    memset( PP0to3S1[2]                 , 0       , sizeof(bool) * 2               ) ;
    memset( PP0to3S1[2] + 2             , Si[1]   , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[2] + 3             , 0       , sizeof(bool) * 1               ) ;
    memcpy( PP0to3S1[2] + 4             , PPi[2]  , sizeof(bool) * (MUL_IN_WD + 1) ) ;
    memset( PP0to3S1[2] + MUL_IN_WD + 5 , Ei[2]   , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[2] + MUL_IN_WD + 6 , 1       , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[2] + MUL_IN_WD + 7 , 0       , sizeof(bool) * 2               ) ;
        // PP0to3S1[3] = { 1'b1, Ei[3], PPi[3], 1'b0, S[2], 4'b0 }
    memset( PP0to3S1[3]                 , 0       , sizeof(bool) * 4               ) ;
    memset( PP0to3S1[3] + 4             , Si[2]   , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[3] + 5             , 0       , sizeof(bool) * 1               ) ;
    memcpy( PP0to3S1[3] + 6             , PPi[3]  , sizeof(bool) * (MUL_IN_WD + 1) ) ;
    memset( PP0to3S1[3] + MUL_IN_WD + 7 , Ei[3]   , sizeof(bool) * 1               ) ;
    memset( PP0to3S1[3] + MUL_IN_WD + 8 , 1       , sizeof(bool) * 1               ) ;
    }

    // compress PP0to3S1
    for( int i = 0 ; i < STAGE_1_PP0T3_IN_WD ; i++ )
    {
        four_two_compressor( PP0to3S1[0][i] , PP0to3S1[1][i] , PP0to3S1[2][i] , PP0to3S1[3][i] , CA0to3S1[i] , SO0to3S1[i] , CO0to3S1[i] , CA0to3S1[i+1] ) ; 
    }

    const int STAGE_1_PP4T7_IN_WD = STAGE_1_PP0T3_IN_WD + BOOTH2_PP_TRA_WD - 1 ;

    bool PP4to7S1[COM_IN_NUM][STAGE_1_PP4T7_IN_WD] ;
    memset( PP4to7S1 , 0 , sizeof(bool) * COM_IN_NUM * STAGE_1_PP4T7_IN_WD ) ;
    bool SO4to7S1[STAGE_1_PP4T7_IN_WD] ;
    bool CO4to7S1[STAGE_1_PP4T7_IN_WD] ;
    bool CA4to7S1[STAGE_1_PP4T7_IN_WD + 1] ; CA4to7S1[0] = 0 ; // one more bit , least bit for cin input 
    // padding sign bit for PP4to7S1
    {
        // PP4to7S1[0] = { 6'b0, 1'b1, Ei[4],  PP4,  1'b0, Si[3] }
    memset( PP4to7S1[0]                 , Si[3]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[0] + 1             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP4to7S1[0] + 2             , PPi[4] , sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP4to7S1[0] + MUL_IN_WD + 3 , Ei[4]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[0] + MUL_IN_WD + 4 , 1      , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[0] + MUL_IN_WD + 5 , 0      , sizeof(bool) * 6                ) ;
        // PP4to7S1[1] = { 4'b0, 1'b1, Ei[5],  PP5,  1'b0, Si[4], 2'b0 }
    memset( PP4to7S1[1]                 , 0      , sizeof(bool) * 2                ) ;
    memset( PP4to7S1[1] + 2             , Si[4]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[1] + 3             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP4to7S1[1] + 4             , PPi[5] , sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP4to7S1[1] + MUL_IN_WD + 5 , Ei[5]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[1] + MUL_IN_WD + 6 , 1      , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[1] + MUL_IN_WD + 7 , 0      , sizeof(bool) * 4                ) ;
        // PP4to7S1[2] = { 2'b0, 1'b1, Ei[6],  PP6,  1'b0, Si[5], 4'b0 }
    memset( PP4to7S1[2]                 , 0      , sizeof(bool) * 4                ) ;
    memset( PP4to7S1[2] + 4             , Si[5]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[2] + 5             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP4to7S1[2] + 6             , PPi[6] , sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP4to7S1[2] + MUL_IN_WD + 7 , Ei[6]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[2] + MUL_IN_WD + 8 , 1      , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[2] + MUL_IN_WD + 9 , 0      , sizeof(bool) * 2                ) ;
        // PP4to7S1[3] = { 1'b1, Ei[7],  PP7, 1'b0,  Si[6], 6'b0 }
    memset( PP4to7S1[3]                 , 0      , sizeof(bool) * 6                ) ;
    memset( PP4to7S1[3] + 6             , Si[6]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[3] + 7             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP4to7S1[3] + 8             , PPi[7] , sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP4to7S1[3] + MUL_IN_WD + 9 , Ei[7]  , sizeof(bool) * 1                ) ;
    memset( PP4to7S1[3] + MUL_IN_WD + 10, 1      , sizeof(bool) * 1                ) ;
    }
    // compress PP4to7S1
    for( int i = 0 ; i < STAGE_1_PP4T7_IN_WD ; i++ )
    {
        four_two_compressor( PP4to7S1[0][i] , PP4to7S1[1][i] , PP4to7S1[2][i] , PP4to7S1[3][i] , CA4to7S1[i] , SO4to7S1[i] , CO4to7S1[i] , CA4to7S1[i+1] ) ; 
    }

    const int STAGE_1_PP8T11_IN_WD = STAGE_1_PP4T7_IN_WD ;

    bool PP8to11S1[COM_IN_NUM][STAGE_1_PP8T11_IN_WD] ;
    memset( PP8to11S1 , 0 , sizeof(bool) * COM_IN_NUM * STAGE_1_PP8T11_IN_WD ) ;
    bool SO8to11S1[STAGE_1_PP8T11_IN_WD] ;
    bool CO8to11S1[STAGE_1_PP8T11_IN_WD] ;
    bool CA8to11S1[STAGE_1_PP8T11_IN_WD + 1] ; CA8to11S1[0] = 0 ; // one more bit , least bit for cin input 
    // padding sign bit for PP8to11S1
    {
        // PP8to11S1[0] = { 6'b0,  1'b1,  Ei[8],  PP8,  1'b0, Si[7] }
    memset( PP8to11S1[0]                 , Si[7]  , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[0] + 1             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP8to11S1[0] + 2             , PPi[8] , sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP8to11S1[0] + MUL_IN_WD + 3 , Ei[8]  , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[0] + MUL_IN_WD + 4 , 1      , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[0] + MUL_IN_WD + 5 , 0      , sizeof(bool) * 6                ) ;
        // PP8to11S1[1] = { 4'b0,  1'b1,  Ei[9],  PP9,  1'b0, Si[8], 2'b0 }
    memset( PP8to11S1[1]                 , 0      , sizeof(bool) * 2                ) ;
    memset( PP8to11S1[1] + 2             , Si[8]  , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[1] + 3             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP8to11S1[1] + 4             , PPi[9] , sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP8to11S1[1] + MUL_IN_WD + 5 , Ei[9]  , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[1] + MUL_IN_WD + 6 , 1      , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[1] + MUL_IN_WD + 7 , 0      , sizeof(bool) * 4                ) ;
        // PP8to11S1[2] = { 2'b0, 1'b1, Ei[10],  PP10,  1'b0, Si[9], 4'b0 }
    memset( PP8to11S1[2]                 , 0      , sizeof(bool) * 4                ) ;
    memset( PP8to11S1[2] + 4             , Si[9]  , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[2] + 5             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP8to11S1[2] + 6             , PPi[10], sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP8to11S1[2] + MUL_IN_WD + 7 , Ei[10] , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[2] + MUL_IN_WD + 8 , 1      , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[2] + MUL_IN_WD + 9 , 0      , sizeof(bool) * 2                ) ;
        // PP8to11S1[3] = { 'b1, Ei[11],  PP11, 1'b0,  Si[10], 6'b0 }
    memset( PP8to11S1[3]                 , 0      , sizeof(bool) * 6                ) ;
    memset( PP8to11S1[3] + 6             , Si[10] , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[3] + 7             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP8to11S1[3] + 8             , PPi[11], sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP8to11S1[3] + MUL_IN_WD + 9 , Ei[11] , sizeof(bool) * 1                ) ;
    memset( PP8to11S1[3] + MUL_IN_WD + 10, 1      , sizeof(bool) * 1                ) ;
    }
    // compress PP8to11S1
    for( int i = 0 ; i < STAGE_1_PP8T11_IN_WD ; i++ )
    {
        four_two_compressor( PP8to11S1[0][i] , PP8to11S1[1][i] , PP8to11S1[2][i] , PP8to11S1[3][i] , CA8to11S1[i] , SO8to11S1[i] , CO8to11S1[i] , CA8to11S1[i+1] ) ; 
    }

    const int STAGE_1_PP12T15_IN_WD = STAGE_1_PP8T11_IN_WD - 1 ;

    bool PP12to15S1[COM_IN_NUM][STAGE_1_PP12T15_IN_WD] ;
    memset( PP12to15S1 , 0 , sizeof(bool) * COM_IN_NUM * STAGE_1_PP12T15_IN_WD ) ;
    bool SO12to15S1[STAGE_1_PP12T15_IN_WD] ;
    bool CO12to15S1[STAGE_1_PP12T15_IN_WD] ;
    bool CA12to15S1[STAGE_1_PP12T15_IN_WD + 1] ; CA12to15S1[0] = 0 ; // one more bit , least bit for cin input 
    // padding sign bit for PP12to15S1
    {
        // PP12to15S1[0] = { 5'b0,  1'b1,  Ei[12],  PP12,  1'b0, Si[11] }
    memset( PP12to15S1[0]                 , Si[11] , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[0] + 1             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP12to15S1[0] + 2             , PPi[12], sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP12to15S1[0] + MUL_IN_WD + 3 , Ei[12] , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[0] + MUL_IN_WD + 4 , 1      , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[0] + MUL_IN_WD + 5 , 0      , sizeof(bool) * 5                ) ;
        // PP12to15S1[1] = { 3'b0,  1'b1,  Ei[13],  PP13,  1'b0, Si[12], 2'b0 }
    memset( PP12to15S1[1]                 , 0      , sizeof(bool) * 2                ) ;
    memset( PP12to15S1[1] + 2             , Si[12] , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[1] + 3             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP12to15S1[1] + 4             , PPi[13], sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP12to15S1[1] + MUL_IN_WD + 5 , Ei[13] , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[1] + MUL_IN_WD + 6 , 1      , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[1] + MUL_IN_WD + 7 , 0      , sizeof(bool) * 3                ) ;
        // PP12to15S1[2] = { 1'b0, 1'b1, Ei[14],  PP14,  1'b0, Si[13], 4'b0 }
    memset( PP12to15S1[2]                 , 0      , sizeof(bool) * 4                ) ;
    memset( PP12to15S1[2] + 4             , Si[13] , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[2] + 5             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP12to15S1[2] + 6             , PPi[14], sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP12to15S1[2] + MUL_IN_WD + 7 , Ei[14] , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[2] + MUL_IN_WD + 8 , 1      , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[2] + MUL_IN_WD + 9 , 0      , sizeof(bool) * 1                ) ;
        // PP12to15S1[3] = { Ei[15],  PP15, 1'b0,  Si[14], 6'b0 }
    memset( PP12to15S1[3]                 , 0      , sizeof(bool) * 6                ) ;
    memset( PP12to15S1[3] + 6             , Si[14] , sizeof(bool) * 1                ) ;
    memset( PP12to15S1[3] + 7             , 0      , sizeof(bool) * 1                ) ;
    memcpy( PP12to15S1[3] + 8             , PPi[15], sizeof(bool) * (MUL_IN_WD + 1)  ) ;
    memset( PP12to15S1[3] + MUL_IN_WD + 9 , Ei[15] , sizeof(bool) * 1                ) ;
    }
    // compress PP12to15S1
    for( int i = 0 ; i < STAGE_1_PP12T15_IN_WD ; i++ )
    {
        four_two_compressor( PP12to15S1[0][i] , PP12to15S1[1][i] , PP12to15S1[2][i] , PP12to15S1[3][i] , CA12to15S1[i] , SO12to15S1[i] , CO12to15S1[i] , CA12to15S1[i+1] ) ;
    }
    // END OF STAGE 1

    // BEGIN OF STAGE 2
    const int STAGE_2_SC0T1_IN_WD = STAGE_1_PP0T3_IN_WD + 9 ;
    bool SC0to1S2[COM_IN_NUM][STAGE_2_SC0T1_IN_WD] ;
    memset( SC0to1S2 , 0 , sizeof(bool) * COM_IN_NUM * STAGE_2_SC0T1_IN_WD ) ;
    bool SO0to1S2[STAGE_2_SC0T1_IN_WD] ;
    bool CO0to1S2[STAGE_2_SC0T1_IN_WD] ;
    bool CA0to1S2[STAGE_2_SC0T1_IN_WD + 1] ; CA0to1S2[0] = 0 ; // one more bit , least bit for cin input
    
    // padding sign bit for SC0to1S2
    {
        // SC0to1S2[0] = { 9'b0 , SO0to3S1 }
    memcpy( SC0to1S2[0]                           , SO0to3S1 , sizeof(bool) * STAGE_1_PP0T3_IN_WD ) ;
    memset( SC0to1S2[0] + STAGE_1_PP0T3_IN_WD     , 0        , sizeof(bool) * 9                   ) ;
        // SC0to1S2[1] = { 8'b0 , CO0to3S1 , 1'b0 }
    memset( SC0to1S2[1]                           , 0        , sizeof(bool) * 1                   ) ;
    memcpy( SC0to1S2[1] + 1                       , CO0to3S1 , sizeof(bool) * STAGE_1_PP0T3_IN_WD ) ;
    memset( SC0to1S2[1] + STAGE_1_PP0T3_IN_WD + 1 , 0        , sizeof(bool) * 8                   ) ;
        // SC0to1S2[2] = { 1'b0 , SO4to7S1 , 6'b0 }
    memset( SC0to1S2[2]                           , 0        , sizeof(bool) * 6                   ) ;
    memcpy( SC0to1S2[2] + 6                       , SO4to7S1 , sizeof(bool) * STAGE_1_PP4T7_IN_WD ) ;
    memset( SC0to1S2[2] + STAGE_1_PP4T7_IN_WD + 6 , 0        , sizeof(bool) * 1                   ) ;
        // SC0to1S2[3] = { CO4to7S1 , 7'b0 }
    memset( SC0to1S2[3]                           , 0        , sizeof(bool) * 7                   ) ;
    memcpy( SC0to1S2[3] + 7                       , CO4to7S1 , sizeof(bool) * STAGE_1_PP4T7_IN_WD ) ;
    }

    // compress SC0to1S2
    for( int i = 0 ; i < STAGE_2_SC0T1_IN_WD ; i++ )
    {
        four_two_compressor( SC0to1S2[0][i] , SC0to1S2[1][i] , SC0to1S2[2][i] , SC0to1S2[3][i] , CA0to1S2[i] , SO0to1S2[i] , CO0to1S2[i] , CA0to1S2[i+1] ) ; 
    }

    const int STAGE_2_SC2T3_IN_WD = STAGE_2_SC0T1_IN_WD ;
    bool SC2to3S2[COM_IN_NUM][STAGE_2_SC2T3_IN_WD] ;
    memset( SC2to3S2 , 0 , sizeof(bool) * COM_IN_NUM * STAGE_2_SC2T3_IN_WD ) ;
    bool SO2to3S2[STAGE_2_SC2T3_IN_WD] ;
    bool CO2to3S2[STAGE_2_SC2T3_IN_WD] ;
    bool CA2to3S2[STAGE_2_SC2T3_IN_WD + 1] ; CA2to3S2[0] = 0 ; // one more bit , least bit for cin input
    
    // padding sign bit for SC2to3S2
    {
        // SC2to3S2[0] = { 7'b0 , SO8to11S1 }
    memcpy( SC2to3S2[0]                            , SO8to11S1 , sizeof(bool) * STAGE_1_PP8T11_IN_WD      ) ;
    memset( SC2to3S2[0] + STAGE_1_PP8T11_IN_WD     , 0         , sizeof(bool) * 7                         ) ;
        // SC2to3S2[1] = { 6'b0 , CO8to11S1 , 1'b0 }
    memset( SC2to3S2[1]                            , 0         , sizeof(bool) * 1                         ) ;
    memcpy( SC2to3S2[1] + 1                        , CO8to11S1 , sizeof(bool) * STAGE_1_PP8T11_IN_WD      ) ;
    memset( SC2to3S2[1] + STAGE_1_PP8T11_IN_WD + 1 , 0         , sizeof(bool) * 6                         ) ;
        // SC2to3S2[2] = { SO12to15S1 , 8'b0 }
    memset( SC2to3S2[2]                            , 0          , sizeof(bool) * 8                        ) ;
    memcpy( SC2to3S2[2] + 8                        , SO12to15S1 , sizeof(bool) * STAGE_1_PP12T15_IN_WD    ) ;
        // SC2to3S2[3] = { CO12to15S1[40:0] , 9'b0 }
    memset( SC2to3S2[3]                            , 0          , sizeof(bool) * 9                        ) ;
    memcpy( SC2to3S2[3] + 9                        , CO12to15S1 , sizeof(bool) * STAGE_1_PP12T15_IN_WD - 1) ;
    }

    // compress SC2to3S2
    for( int i = 0 ; i < STAGE_2_SC2T3_IN_WD ; i++ )
    {
        four_two_compressor( SC2to3S2[0][i] , SC2to3S2[1][i] , SC2to3S2[2][i] , SC2to3S2[3][i] , CA2to3S2[i] , SO2to3S2[i] , CO2to3S2[i] , CA2to3S2[i+1] ) ; 
    }
    // END OF STAGE 2

    // BEGIN OF STAGE 3
    const int STAGE_3_SC0T1_IN_WD = MUL_OUT_WD ;
    bool SC0to1S3[COM_IN_NUM][STAGE_3_SC0T1_IN_WD] ;
    memset( SC0to1S3 , 0 , sizeof(bool) * COM_IN_NUM * STAGE_3_SC0T1_IN_WD ) ;
    bool SO0to1S3[STAGE_3_SC0T1_IN_WD] ;
    bool CO0to1S3[STAGE_3_SC0T1_IN_WD] ;
    bool CA0to1S3[STAGE_3_SC0T1_IN_WD + 1] ; CA0to1S3[0] = 0 ; // one more bit , least bit for cin input
    // END OF STAGE 3

    // padding sign bit for SC0to1S3
    {
        // SC0to1S3[0] = { 14'b0,    SO0to1S2 }
    memcpy( SC0to1S3[0]                           , SO0to1S2 , sizeof(bool) * STAGE_2_SC0T1_IN_WD    ) ;
    memset( SC0to1S3[0] + STAGE_2_SC0T1_IN_WD     , 0        , sizeof(bool) * 14                     ) ;
        // SC0to1S3[1] = { 13'b0, CO0to1S2,  1'b0 }
    memset( SC0to1S3[1]                           , 0        , sizeof(bool) * 1                      ) ;
    memcpy( SC0to1S3[1] + 1                       , CO0to1S2 , sizeof(bool) * STAGE_2_SC0T1_IN_WD    ) ;
    memset( SC0to1S3[1] + STAGE_2_SC0T1_IN_WD + 1 , 0        , sizeof(bool) * 13                     ) ;
        // SC0to1S3[2] = { SO2to3S2, 14'b0 }
    memset( SC0to1S3[2]                           , 0        , sizeof(bool) * 14                     ) ;
    memcpy( SC0to1S3[2] + 14                      , SO2to3S2 , sizeof(bool) * STAGE_2_SC2T3_IN_WD    ) ;
        // SC0to1S3[3] = { CO2to3S2[48:0], 15'b0 }
    memset( SC0to1S3[3]                           , 0        , sizeof(bool) * 15                     ) ;
    memcpy( SC0to1S3[3] + 15                      , CO2to3S2 , sizeof(bool) * STAGE_2_SC2T3_IN_WD - 1) ;
    }

    // compress SC0to1S3
    for( int i = 0 ; i < STAGE_3_SC0T1_IN_WD ; i++ )
    {
        four_two_compressor( SC0to1S3[0][i] , SC0to1S3[1][i] , SC0to1S3[2][i] , SC0to1S3[3][i] , CA0to1S3[i] , SO0to1S3[i] , CO0to1S3[i] , CA0to1S3[i+1] ) ; 
    }

    memcpy( So , SO0to1S3 , MUL_OUT_WD ) ;
    memcpy( Co , CO0to1S3 , MUL_OUT_WD ) ;

    return ;
}

// booth2 mul top
void booth2_mul_top( bool Ai[MUL_IN_WD] , bool Bi[MUL_IN_WD] , bool Mo[MUL_OUT_WD] )
{
    bool regPPo[BOOTH2_PP_TRA_NUM][MUL_IN_WD + 1] ;
    bool regSo[BOOTH2_PP_TRA_NUM] ;
    bool regEo[BOOTH2_PP_TRA_NUM] ;
    booth2_all_pp_generator( Ai , Bi , regPPo , regSo , regEo ) ;
    bool regSum[MUL_OUT_WD] ;
    bool regCout[MUL_OUT_WD] ;
    binary_tree_compressor_array( regPPo , regSo , regEo , regSum , regCout ) ;
    bool regCarry0[MUL_OUT_WD / PIPLINE_ADDER_WD] ;
    bool regAdd0[MUL_OUT_WD] ;
    bool regMo[MUL_OUT_WD] ;
    memset( regAdd0 , 0 , MUL_OUT_WD) ;
    memcpy( regAdd0 + 1 , regCout , MUL_OUT_WD - 1 ) ;
    adder_carry_look_ahead_16bit( regAdd0 + PIPLINE_ADDER_WD * 0 , regSum + PIPLINE_ADDER_WD * 0 , 0            , regMo + PIPLINE_ADDER_WD * 0 , regCarry0[0] ) ;
    adder_carry_look_ahead_16bit( regAdd0 + PIPLINE_ADDER_WD * 1 , regSum + PIPLINE_ADDER_WD * 1 , regCarry0[0] , regMo + PIPLINE_ADDER_WD * 1 , regCarry0[1] ) ;
    adder_carry_look_ahead_16bit( regAdd0 + PIPLINE_ADDER_WD * 2 , regSum + PIPLINE_ADDER_WD * 2 , regCarry0[1] , regMo + PIPLINE_ADDER_WD * 2 , regCarry0[2] ) ;
    adder_carry_look_ahead_16bit( regAdd0 + PIPLINE_ADDER_WD * 3 , regSum + PIPLINE_ADDER_WD * 3 , regCarry0[2] , regMo + PIPLINE_ADDER_WD * 3 , regCarry0[3] ) ;
    bool regCarry1[MUL_OUT_WD / PIPLINE_ADDER_WD] ;
    bool regAdd1[MUL_OUT_WD] ;
    memset( regAdd1 , 0 , MUL_OUT_WD) ;
    regAdd1[(BOOTH2_PP_TRA_NUM - 1) * 2] = regSo[BOOTH2_PP_TRA_NUM - 1] ;
    adder_carry_look_ahead_16bit( regAdd1 + PIPLINE_ADDER_WD * 0 , regMo + PIPLINE_ADDER_WD * 0 , 0            , Mo + PIPLINE_ADDER_WD * 0 , regCarry1[0] ) ;
    adder_carry_look_ahead_16bit( regAdd1 + PIPLINE_ADDER_WD * 1 , regMo + PIPLINE_ADDER_WD * 1 , regCarry1[0] , Mo + PIPLINE_ADDER_WD * 1 , regCarry1[1] ) ;
    adder_carry_look_ahead_16bit( regAdd1 + PIPLINE_ADDER_WD * 2 , regMo + PIPLINE_ADDER_WD * 2 , regCarry1[1] , Mo + PIPLINE_ADDER_WD * 2 , regCarry1[2] ) ;
    adder_carry_look_ahead_16bit( regAdd1 + PIPLINE_ADDER_WD * 3 , regMo + PIPLINE_ADDER_WD * 3 , regCarry1[2] , Mo + PIPLINE_ADDER_WD * 3 , regCarry1[3] ) ;
    return ;
}

// mul anchor
void mul_anchor( int32_t Ai , int32_t Bi , int64_t & Mo )
{
    int64_t longAi = Ai ;
    int64_t longBi = Bi ;
    Mo = longAi * longBi ;
}

// bool_array_to_int64
int64_t bool_array_to_int64( bool BoolIn[64] , int BitWidth = MUL_OUT_WD)
{
    bool signBit = BoolIn[BitWidth - 1] ;
    bool tmp[BitWidth] ;
    memcpy( tmp , BoolIn , BitWidth ) ; 
    int64_t result = 0 ;
    if( signBit )
    {
        for( int i = 0 ; i < BitWidth ; i++ )
        {
            tmp[i] = tmp[i] ? 0 : 1 ;
        }
        bool carryBit = 1 ;
        for( int i = 0 ; i < BitWidth ; i++ )
        {
            if( tmp[i] && carryBit )
            {
                carryBit = 1 ;
                tmp[i] = 0 ;
            }
            else if ( carryBit )
            {
                carryBit = 0 ;
                tmp[i] = 1 ;
            }
            else
            {
                carryBit = 0 ;
            }
        }
    }
    for( int i = BitWidth - 2 ; i > -1 ; i--)
    {
        result = result << 1 ;
        result += tmp[i] ;
    }
    result = signBit ? -1 * result : result ;
    return result ;
}

// bool_array_to_int32
int32_t bool_array_to_int32( bool BoolIn[32] , int BitWidth = MUL_IN_WD)
{
    bool signBit = BoolIn[BitWidth - 1] ;
    bool tmp[BitWidth] ;
    memcpy( tmp , BoolIn , BitWidth ) ; 
    int32_t result = 0 ;
    if( signBit )
    {
        for( int i = 0 ; i < BitWidth ; i++ )
        {
            tmp[i] = tmp[i] ? 0 : 1 ;
        }
        bool carryBit = 1 ;
        for( int i = 0 ; i < BitWidth ; i++ )
        {
            if( tmp[i] && carryBit )
            {
                carryBit = 1 ;
                tmp[i] = 0 ;
            }
            else if ( carryBit )
            {
                carryBit = 0 ;
                tmp[i] = 1 ;
            }
            else
            {
                carryBit = 0 ;
            }
        }
    }
    for( int i = BitWidth - 2 ; i > -1 ; i--)
    {
        result = result << 1 ;
        result += tmp[i] ;
    }
    result = signBit ? -1 * result : result ;
    return result ;
}

void check( int32_t Ai , int32_t Bi , bool boolMo[MUL_OUT_WD] , int64_t intMo )
{
    int64_t test = bool_array_to_int64( boolMo , MUL_OUT_WD ) ;
    if( test != intMo )
    {
        printf("Ai:%d\tBi:%d\tAnchor:%ld\tTest:%ld\n",Ai,Bi,intMo,test) ;
    }
    return ;

}

void dump( bool Ai[MUL_IN_WD] , bool Bi[MUL_IN_WD] , bool Mo[MUL_OUT_WD] )
{

    FILE * fp ;

    fp = fopen( "dut_setting.vh" , "w" ) ;
    fprintf( fp , "`define\tMUL_IN_WD\t%d\n", MUL_IN_WD) ;
    fprintf( fp , "`define\tMUL_OUT_WD\t%d\n", MUL_OUT_WD) ;
    fprintf( fp , "`define\tTEST_NUM\t%d\n", TEST_NUM) ;
    fclose(fp) ;


    int cnt = 0 ; int sum = 0 ;
    fp = fopen( "Ai.dat" , "a" ) ;
    sum = 0 ; cnt = 0 ;
    for( int i = MUL_IN_WD - 1; i > -1 ; i-- )
    {
        cnt += 1 ;
        sum = sum << 1 ;
        sum += Ai[i] ;
        if( cnt == 4 )
        {
            fprintf( fp , "%x" , sum ) ;
            cnt = 0 ;
            sum = 0 ;
        }
    }
    fprintf( fp , "\n" ) ;
    fclose(fp) ;

    fp = fopen( "Bi.dat" , "a" ) ;
    sum = 0 ; cnt = 0 ;
    for( int i = MUL_IN_WD - 1; i > -1 ; i-- )
    {
        cnt += 1 ;
        sum = sum << 1 ;
        sum += Bi[i] ;
        if( cnt == 4 )
        {
            fprintf( fp , "%x" , sum ) ;
            cnt = 0 ;
            sum = 0 ;
        }
    }
    fprintf( fp , "\n" ) ;
    fclose(fp) ;

    fp = fopen( "Mo.dat" , "a" ) ;
    sum = 0 ; cnt = 0 ;
    for( int i = MUL_OUT_WD - 1; i > -1 ; i-- )
    {
        cnt += 1 ;
        sum = sum << 1 ;
        sum += Mo[i] ;
        if( cnt == 4 )
        {
            fprintf( fp , "%x" , sum ) ;
            cnt = 0 ;
            sum = 0 ;
        }
    }
    fprintf( fp , "\n" ) ;
    fclose(fp) ;

    return ;
}

int main()
{
    std::random_device seed ;
    std::ranlux48 engine(seed()) ;
    std::uniform_int_distribution<> distrib(0,1) ;
    
    bool Ai[MUL_IN_WD] ;
    bool Bi[MUL_IN_WD] ;
    bool Mo[MUL_OUT_WD] ;
    memset( Ai , 0 , sizeof(bool) * MUL_IN_WD ) ;
    memset( Bi , 0 , sizeof(bool) * MUL_IN_WD ) ;

    for( int i = 0 ; i < TEST_NUM ; i++ )
    {
        for( int j = 0 ; j < MUL_IN_WD ; j++ )
        {
            Ai[j] = distrib(engine) ;
            Bi[j] = distrib(engine) ;
        }

        int32_t intAi = bool_array_to_int32( Ai , MUL_IN_WD ) ;
        int32_t intBi = bool_array_to_int32( Bi , MUL_IN_WD ) ;
        int64_t intMo ;
        mul_anchor( intAi , intBi , intMo ) ;

        booth2_mul_top( Ai , Bi , Mo ) ;
        check( intAi , intBi , Mo , intMo ) ;
        dump( Ai , Bi , Mo ) ;
    }
}