// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

////////////////////////////////////////
// A) The following code was imported from "fips202.c"
// Based on the public domain implementation in
// crypto_hash/keccakc512/simple/ from http://bench.cr.yp.to/supercop.html
// by Ronny Van Keer
// and the public domain "TweetFips202" implementation
// from https://twitter.com/tweetfips202
// by Gilles Van Assche, Daniel J. Bernstein, and Peter Schwabe
// License: Public domain
//
// B) SHAKE256_RATE constant from...
// file: sha3_c.c
// brief: Implementation of the OQS SHA3 API via the files fips202.c
// from: PQClean (https://github.com/PQClean/PQClean/tree/master/common)
// License: MIT
////////////////////////////////////////

contract lib_falcon_sha3_c
{
    uint32 constant SHAKE256_RATE = 136;  // The SHAKE-256 byte absorption rate (aka OQS_SHA3_SHAKE256_RATE)

    ///////////////////////////////////////
    // Constants
    ///////////////////////////////////////
    int16 constant private CTX_ELEMENTS = 26; // Number of uint64 context elements
    int16 constant private PQC_SHAKEINCCTX_BYTES = (8 * CTX_ELEMENTS); // (sizeof(uint64) * 26)
    int16 constant private NROUNDS = 24;

    ///////////////////////////////////////
    // Variables
    ///////////////////////////////////////
    // Space to hold the state of the SHAKE-256 incremental hashing API.
    // uint64[26]: Input/Output incremental state
    //              * First 25 values represent Keccak state.
    //              * 26th value represents either the number of absorbed bytes
    //                that have not been permuted, or not-yet-squeezed bytes.
    //byte[PQC_SHAKEINCCTX_BYTES]  constant private  shake256_context; // Internal state.
    uint64[CTX_ELEMENTS] private shake256_context64; // Internal state.

    // Keccak round constants
    uint64[NROUNDS] private KeccakF_RoundConstants =
    [
    	0x0000000000000001, 0x0000000000008082,
    	0x800000000000808a, 0x8000000080008000,
    	0x000000000000808b, 0x0000000080000001,
    	0x8000000080008081, 0x8000000000008009,
    	0x000000000000008a, 0x0000000000000088,
    	0x0000000080008009, 0x000000008000000a,
    	0x000000008000808b, 0x800000000000008b,
    	0x8000000000008089, 0x8000000000008003,
    	0x8000000000008002, 0x8000000000000080,
    	0x000000000000800a, 0x800000008000000a,
    	0x8000000080008081, 0x8000000000008080,
    	0x0000000080000001, 0x8000000080008008
    ];

    ///////////////////////////////////////
    // Implementation: Keccak
    ///////////////////////////////////////

    ////////////////////////////////////////
    // Solidity implementation of the macro...
    // #define ROL(a, offset) (((a) << (offset)) ^ ((a) >> (64 - (offset))))
    ////////////////////////////////////////
    function ROL(uint64 a, uint16 offset) private pure returns (uint64)
    {
        return (((a) << (offset)) ^ ((a) >> (64 - (offset))));
    }


/* TODO: Stack usage is too high
    ////////////////////////////////////////
    // KeccakF1600_StatePermute()
    // Input parameters supplied in member variable shake256_context64.
    // Output values are written to the same member variable.
    ////////////////////////////////////////
    function KeccakF1600_StatePermute() public payable 
    {
        //fprintf(stdout, "TRACE: KeccakF1600_StatePermute()\n");
        int         round;
        uint64 Aba; uint64 Abe; uint64 Abi; uint64 Abo; uint64 Abu;
        uint64 Aga; uint64 Age; uint64 Agi; uint64 Ago; uint64 Agu;
        uint64 Aka; uint64 Ake; uint64 Aki; uint64 Ako; uint64 Aku;
        uint64 Ama; uint64 Ame; uint64 Ami; uint64 Amo; uint64 Amu;
        uint64 Asa; uint64 Ase; uint64 Asi; uint64 Aso; uint64 Asu;
        uint64 BCa; uint64 BCe; uint64 BCi; uint64 BCo; uint64 BCu;
        uint64 Da ; uint64 De ; uint64 Di ; uint64 Do ; uint64 Du ;
        uint64 Eba; uint64 Ebe; uint64 Ebi; uint64 Ebo; uint64 Ebu;
        uint64 Ega; uint64 Ege; uint64 Egi; uint64 Ego; uint64 Egu;
        uint64 Eka; uint64 Eke; uint64 Eki; uint64 Eko; uint64 Eku;
        uint64 Ema; uint64 Eme; uint64 Emi; uint64 Emo; uint64 Emu;
        uint64 Esa; uint64 Ese; uint64 Esi; uint64 Eso; uint64 Esu;

        // copyFromState(A, state)
        Aba = shake256_context64[ 0]; Abe = shake256_context64[ 1]; Abi = shake256_context64[ 2]; Abo = shake256_context64[ 3]; Abu = shake256_context64[ 4];
        Aga = shake256_context64[ 5]; Age = shake256_context64[ 6]; Agi = shake256_context64[ 7]; Ago = shake256_context64[ 8]; Agu = shake256_context64[ 9];
        Aka = shake256_context64[10]; Ake = shake256_context64[11]; Aki = shake256_context64[12]; Ako = shake256_context64[13]; Aku = shake256_context64[14];
        Ama = shake256_context64[15]; Ame = shake256_context64[16]; Ami = shake256_context64[17]; Amo = shake256_context64[18]; Amu = shake256_context64[19];
        Asa = shake256_context64[20]; Ase = shake256_context64[21]; Asi = shake256_context64[22]; Aso = shake256_context64[23]; Asu = shake256_context64[24];

        for (round = 0; round < NROUNDS; round += 2)
        {
            //    prepareTheta
            BCa = Aba ^ Aga ^ Aka ^ Ama ^ Asa;
            BCe = Abe ^ Age ^ Ake ^ Ame ^ Ase;
            BCi = Abi ^ Agi ^ Aki ^ Ami ^ Asi;
            BCo = Abo ^ Ago ^ Ako ^ Amo ^ Aso;
            BCu = Abu ^ Agu ^ Aku ^ Amu ^ Asu;

            // thetaRhoPiChiIotaPrepareTheta(round  , A, E)
            Da = BCu ^ ROL(BCe, 1);
            De = BCa ^ ROL(BCi, 1);
            Di = BCe ^ ROL(BCo, 1);
            Do = BCi ^ ROL(BCu, 1);
            Du = BCo ^ ROL(BCa, 1);
            Aba ^= Da;
            BCa = Aba;
            Age ^= De;
            BCe = ROL(Age, 44);
            Aki ^= Di;
            BCi = ROL(Aki, 43);
            Amo ^= Do;
            BCo = ROL(Amo, 21);
            Asu ^= Du;
            BCu = ROL(Asu, 14);
            Eba = BCa ^ ((~BCe) & BCi);
            Eba ^= KeccakF_RoundConstants[uint256(round)];
            Ebe = BCe ^ ((~BCi) & BCo);
            Ebi = BCi ^ ((~BCo) & BCu);
            Ebo = BCo ^ ((~BCu) & BCa);
            Ebu = BCu ^ ((~BCa) & BCe);
            Abo ^= Do;
            BCa = ROL(Abo, 28);
            Agu ^= Du;
            BCe = ROL(Agu, 20);
            Aka ^= Da;
            BCi = ROL(Aka, 3);
            Ame ^= De;
            BCo = ROL(Ame, 45);
            Asi ^= Di;
            BCu = ROL(Asi, 61);
            Ega = BCa ^ ((~BCe) & BCi);
            Ege = BCe ^ ((~BCi) & BCo);
            Egi = BCi ^ ((~BCo) & BCu);
            Ego = BCo ^ ((~BCu) & BCa);
            Egu = BCu ^ ((~BCa) & BCe);
            Abe ^= De;
            BCa = ROL(Abe, 1);
            Agi ^= Di;
            BCe = ROL(Agi, 6);
            Ako ^= Do;
            BCi = ROL(Ako, 25);
            Amu ^= Du;
            BCo = ROL(Amu, 8);
            Asa ^= Da;
            BCu = ROL(Asa, 18);
            Eka = BCa ^ ((~BCe) & BCi);
            Eke = BCe ^ ((~BCi) & BCo);
            Eki = BCi ^ ((~BCo) & BCu);
            Eko = BCo ^ ((~BCu) & BCa);
            Eku = BCu ^ ((~BCa) & BCe);
            Abu ^= Du;
            BCa = ROL(Abu, 27);
            Aga ^= Da;
            BCe = ROL(Aga, 36);
            Ake ^= De;
            BCi = ROL(Ake, 10);
            Ami ^= Di;
            BCo = ROL(Ami, 15);
            Aso ^= Do;
            BCu = ROL(Aso, 56);
            Ema = BCa ^ ((~BCe) & BCi);
            Eme = BCe ^ ((~BCi) & BCo);
            Emi = BCi ^ ((~BCo) & BCu);
            Emo = BCo ^ ((~BCu) & BCa);
            Emu = BCu ^ ((~BCa) & BCe);
            Abi ^= Di;
            BCa = ROL(Abi, 62);
            Ago ^= Do;
            BCe = ROL(Ago, 55);
            Aku ^= Du;
            BCi = ROL(Aku, 39);
            Ama ^= Da;
            BCo = ROL(Ama, 41);
            Ase ^= De;
            BCu = ROL(Ase, 2);
            Esa = BCa ^ ((~BCe) & BCi);
            Ese = BCe ^ ((~BCi) & BCo);
            Esi = BCi ^ ((~BCo) & BCu);
            Eso = BCo ^ ((~BCu) & BCa);
            Esu = BCu ^ ((~BCa) & BCe);

            //    prepareTheta
            BCa = Eba ^ Ega ^ Eka ^ Ema ^ Esa;
            BCe = Ebe ^ Ege ^ Eke ^ Eme ^ Ese;
            BCi = Ebi ^ Egi ^ Eki ^ Emi ^ Esi;
            BCo = Ebo ^ Ego ^ Eko ^ Emo ^ Eso;
            BCu = Ebu ^ Egu ^ Eku ^ Emu ^ Esu;

            // thetaRhoPiChiIotaPrepareTheta(round+1, E, A)
            Da = BCu ^ ROL(BCe, 1);
            De = BCa ^ ROL(BCi, 1);
            Di = BCe ^ ROL(BCo, 1);
            Do = BCi ^ ROL(BCu, 1);
            Du = BCo ^ ROL(BCa, 1);
            Eba ^= Da;
            BCa = Eba;
            Ege ^= De;
            BCe = ROL(Ege, 44);
            Eki ^= Di;
            BCi = ROL(Eki, 43);
            Emo ^= Do;
            BCo = ROL(Emo, 21);
            Esu ^= Du;
            BCu = ROL(Esu, 14);
            Aba = BCa ^ ((~BCe) & BCi);
            Aba ^= KeccakF_RoundConstants[uint256(round + 1)];
            Abe = BCe ^ ((~BCi) & BCo);
            Abi = BCi ^ ((~BCo) & BCu);
            Abo = BCo ^ ((~BCu) & BCa);
            Abu = BCu ^ ((~BCa) & BCe);
            Ebo ^= Do;
            BCa = ROL(Ebo, 28);
            Egu ^= Du;
            BCe = ROL(Egu, 20);
            Eka ^= Da;
            BCi = ROL(Eka, 3);
            Eme ^= De;
            BCo = ROL(Eme, 45);
            Esi ^= Di;
            BCu = ROL(Esi, 61);
            Aga = BCa ^ ((~BCe) & BCi);
            Age = BCe ^ ((~BCi) & BCo);
            Agi = BCi ^ ((~BCo) & BCu);
            Ago = BCo ^ ((~BCu) & BCa);
            Agu = BCu ^ ((~BCa) & BCe);
            Ebe ^= De;
            BCa = ROL(Ebe, 1);
            Egi ^= Di;
            BCe = ROL(Egi, 6);
            Eko ^= Do;
            BCi = ROL(Eko, 25);
            Emu ^= Du;
            BCo = ROL(Emu, 8);
            Esa ^= Da;
            BCu = ROL(Esa, 18);
            Aka = BCa ^ ((~BCe) & BCi);
            Ake = BCe ^ ((~BCi) & BCo);
            Aki = BCi ^ ((~BCo) & BCu);
            Ako = BCo ^ ((~BCu) & BCa);
            Aku = BCu ^ ((~BCa) & BCe);
            Ebu ^= Du;
            BCa = ROL(Ebu, 27);
            Ega ^= Da;
            BCe = ROL(Ega, 36);
            Eke ^= De;
            BCi = ROL(Eke, 10);
            Emi ^= Di;
            BCo = ROL(Emi, 15);
            Eso ^= Do;
            BCu = ROL(Eso, 56);
            Ama = BCa ^ ((~BCe) & BCi);
            Ame = BCe ^ ((~BCi) & BCo);
            Ami = BCi ^ ((~BCo) & BCu);
            Amo = BCo ^ ((~BCu) & BCa);
            Amu = BCu ^ ((~BCa) & BCe);
            Ebi ^= Di;
            BCa = ROL(Ebi, 62);
            Ego ^= Do;
            BCe = ROL(Ego, 55);
            Eku ^= Du;
            BCi = ROL(Eku, 39);
            Ema ^= Da;
            BCo = ROL(Ema, 41);
            Ese ^= De;
            BCu = ROL(Ese, 2);
            Asa = BCa ^ ((~BCe) & BCi);
            Ase = BCe ^ ((~BCi) & BCo);
            Asi = BCi ^ ((~BCo) & BCu);
            Aso = BCo ^ ((~BCu) & BCa);
            Asu = BCu ^ ((~BCa) & BCe);
        }

        // copyToState(state, A)
        shake256_context64[ 0] = Aba; shake256_context64[ 1] = Abe; shake256_context64[ 2] = Abi; shake256_context64[ 3] = Abo; shake256_context64[ 4] = Abu;
        shake256_context64[ 5] = Aga; shake256_context64[ 6] = Age; shake256_context64[ 7] = Agi; shake256_context64[ 8] = Ago; shake256_context64[ 9] = Agu;
        shake256_context64[10] = Aka; shake256_context64[11] = Ake; shake256_context64[12] = Aki; shake256_context64[13] = Ako; shake256_context64[14] = Aku;
        shake256_context64[15] = Ama; shake256_context64[16] = Ame; shake256_context64[17] = Ami; shake256_context64[18] = Amo; shake256_context64[19] = Amu;
        shake256_context64[20] = Asa; shake256_context64[21] = Ase; shake256_context64[22] = Asi; shake256_context64[23] = Aso; shake256_context64[24] = Asu;
    }
*/

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function keccak_inc_init() public payable
    {
        uint32  i;

        //fprintf(stdout, "TRACE: keccak_inc_init()\n");
        for (i = 0; i < 25; ++i)
        {
            shake256_context64[i] = 0;
        }
        shake256_context64[25] = 0;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function keccak_inc_absorb(uint32 r, bytes memory m, uint32 mlen) public pure
    {
/* TODO: 
        uint32  i;

        //fprintf(stdout, "TRACE: keccak_inc_absorb()\n");
        while (mlen + shake256_context64[25] >= r)
        {
            for (i = 0; i < r - uint32(shake256_context64[25]); i++)
            {
                ///////////////////////////////////////////////////////////////////////////
                //uint64 x = shake256_context64[(shake256_context64[25] + i) >> 3];
                //uint64 y5 = shake256_context64[25] + i;
                //uint64 y6 = y5 & 0x07;
                //uint64 y7 = 8 * y6;
                //uint8  y8 = uint8(m[i]);
                //uint64 y9 = uint64(y8);
                //uint64 y = y9 << y7;
                //
                //x ^= y;
                ///////////////////////////////////////////////////////////////////////////
                
                shake256_context64[(shake256_context64[25] + i) >> 3] ^= (uint64(uint8(m[i])) << (8 * ((shake256_context64[25] + i) & 0x07)));
            }
            mlen -= uint32(r - shake256_context64[25]);
            m += (r - shake256_context64[25]);
            shake256_context64[25] = 0;

            // Input parameters supplied in member variable shake256_context64.
            // Output values are written to the same member variable.
            KeccakF1600_StatePermute();
        }

        for (i = 0; i < mlen; i++)
        {
            shake256_context64[(shake256_context64[25] + i) >> 3] ^= (uint64(uint8(m[i])) << (8 * ((shake256_context64[25] + i) & 0x07)));
        }
        shake256_context64[25] += mlen;
*/
    }

    /*************************************************
     * Name:        keccak_inc_finalize
     *
     * Description: Finalizes Keccak absorb phase, prepares for squeezing
     *
     * Arguments:   - uint32 r     : rate in bytes (e.g., 168 for SHAKE128)
     *              - uint8 p      : domain-separation byte for different Keccak-derived functions
     **************************************************/
    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function keccak_inc_finalize(uint32 r, uint8 p) public payable
    {
        //fprintf(stdout, "TRACE: keccak_inc_finalize()\n");
        shake256_context64[shake256_context64[25] >> 3] ^= uint64(p) << (8 * (shake256_context64[25] & 0x07));
        shake256_context64[(r - 1) >> 3] ^= (uint64(128) << (8 * ((r - 1) & 0x07)));
        shake256_context64[25] = 0;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function keccak_inc_squeeze(/*uint8* h, */ uint32 outlen, uint32 r) private pure returns (bytes memory h)
    {
        //fprintf(stdout, "TRACE: keccak_inc_squeeze()\n");
        uint32  i;

/* TODO: 
        for (i = 0; i < outlen && i < shake256_context64[25]; i++)
        {
            h[i] = uint8(shake256_context64[(r - shake256_context64[25] + i) >> 3] >> (8 * ((r - shake256_context64[25] + i) & 0x07)));
        }

        h += i;
        outlen -= i;
        shake256_context64[25] -= i;

        while (outlen > 0)
        {
            // Input parameters supplied in member variable shake256_context64.
            // Output values are written to the same member variable.
            KeccakF1600_StatePermute(shake256_context64);
            for (i = 0; i < outlen && i < r; i++)
            {
                h[i] = uint8(shake256_context64[i >> 3] >> (8 * (i & 0x07)));
            }

            h += i;
            outlen -= i;
            shake256_context64[25] = r - i;
        }
*/
        r = r;
        for (i = 0; i < outlen; i++)
        {
            h[i] = 0xAA;
        }

    }

    ///////////////////////////////////////
    // Implementation: OQS_SHA3_shake256_inc
    ///////////////////////////////////////

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_init() public payable 
    {
        int16 ii;
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_init()\n");
        for (ii=0; ii < CTX_ELEMENTS; ii++)
            shake256_context64[uint256(ii)] = 0;
        keccak_inc_init();
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_absorb(bytes memory input, uint32 inlen) public pure
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_absorb()\n");
        keccak_inc_absorb(SHAKE256_RATE, input, inlen);
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_finalize() public payable
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_finalize()\n");
        keccak_inc_finalize(SHAKE256_RATE, 0x1F);
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_squeeze(/*uint8* output,*/ uint32 outlen) public pure returns (bytes memory output)
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_squeeze()\n");
        output = keccak_inc_squeeze(outlen, SHAKE256_RATE);
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_ctx_release() public payable
    {
        int16 ii;
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_ctx_release()\n");
        // Blat over any sensitive data
        for (ii=0; ii < CTX_ELEMENTS; ii++)
            shake256_context64[uint256(ii)] = 0;
    }

}
