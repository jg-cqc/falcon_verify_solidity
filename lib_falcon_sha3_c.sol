// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;


library lib_falcon_sha3_c
{
    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    /**
    * \file sha3_c.c
    * \brief Implementation of the OQS SHA3 API via the files fips202.c
    * from PQClean (https://github.com/PQClean/PQClean/tree/master/common)
    *
    * SPDX-License-Identifier: MIT
    */


    #define OQS_SHA3_SHAKE256_RATE  136  // The SHAKE-256 byte absorption rate
    #define SHAKE256_RATE  OQS_SHA3_SHAKE256_RATE
    #define shake256       OQS_SHA3_shake256

    // The following code was imported from "fips202.c"

    /* Based on the public domain implementation in
     * crypto_hash/keccakc512/simple/ from http://bench.cr.yp.to/supercop.html
     * by Ronny Van Keer
     * and the public domain "TweetFips202" implementation
     * from https://twitter.com/tweetfips202
     * by Gilles Van Assche, Daniel J. Bernstein, and Peter Schwabe
     * SPDX-License-Identifier: Public domain
     */

    ///////////////////////////////////////
    // Macros
    ///////////////////////////////////////
    //#define ROL(a, offset) (((a) << (offset)) ^ ((a) >> (64 - (offset))))

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function ROL(uint64 a, uint16 offset) private pure returns (uint64)
    {
        return (((a) << (offset)) ^ ((a) >> (64 - (offset))));
    }

    ///////////////////////////////////////
    // Constants
    ///////////////////////////////////////
    const private int16 PQC_SHAKEINCCTX_BYTES = (8 * 26); // (sizeof(uint64) * 26)
    const private int16 NROUNDS = 24;

    ///////////////////////////////////////
    // Variables
    ///////////////////////////////////////
    // Space to hold the state of the SHAKE-256 incremental hashing API.
    //uint64[26]: Input/Output incremental state
    //              * First 25 values represent Keccak state.
    //              * 26th value represents either the number of absorbed bytes
    //                that have not been permuted, or not-yet-squeezed bytes.
    const private byte[PQC_SHAKEINCCTX_BYTES] shake256_context; // Internal state.

    /* Keccak round constants */
    const private uint64[NROUNDS] KeccakF_RoundConstants =
    {
    	0x0000000000000001ULL, 0x0000000000008082ULL,
    	0x800000000000808aULL, 0x8000000080008000ULL,
    	0x000000000000808bULL, 0x0000000080000001ULL,
    	0x8000000080008081ULL, 0x8000000000008009ULL,
    	0x000000000000008aULL, 0x0000000000000088ULL,
    	0x0000000080008009ULL, 0x000000008000000aULL,
    	0x000000008000808bULL, 0x800000000000008bULL,
    	0x8000000000008089ULL, 0x8000000000008003ULL,
    	0x8000000000008002ULL, 0x8000000000000080ULL,
    	0x000000000000800aULL, 0x800000008000000aULL,
    	0x8000000080008081ULL, 0x8000000000008080ULL,
    	0x0000000080000001ULL, 0x8000000080008008ULL
    };

    ///////////////////////////////////////
    // Implementation: Keccak
    ///////////////////////////////////////

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function KeccakF1600_StatePermute(uint64* state) private pure
    {
        //fprintf(stdout, "TRACE: KeccakF1600_StatePermute()\n");
        int         round;
        uint64    Aba, Abe, Abi, Abo, Abu;
        uint64    Aga, Age, Agi, Ago, Agu;
        uint64    Aka, Ake, Aki, Ako, Aku;
        uint64    Ama, Ame, Ami, Amo, Amu;
        uint64    Asa, Ase, Asi, Aso, Asu;
        uint64    BCa, BCe, BCi, BCo, BCu;
        uint64    Da , De , Di , Do , Du ;
        uint64    Eba, Ebe, Ebi, Ebo, Ebu;
        uint64    Ega, Ege, Egi, Ego, Egu;
        uint64    Eka, Eke, Eki, Eko, Eku;
        uint64    Ema, Eme, Emi, Emo, Emu;
        uint64    Esa, Ese, Esi, Eso, Esu;

        // copyFromState(A, state)
        Aba = state[ 0]; Abe = state[ 1]; Abi = state[ 2]; Abo = state[ 3]; Abu = state[ 4];
        Aga = state[ 5]; Age = state[ 6]; Agi = state[ 7]; Ago = state[ 8]; Agu = state[ 9];
        Aka = state[10]; Ake = state[11]; Aki = state[12]; Ako = state[13]; Aku = state[14];
        Ama = state[15]; Ame = state[16]; Ami = state[17]; Amo = state[18]; Amu = state[19];
        Asa = state[20]; Ase = state[21]; Asi = state[22]; Aso = state[23]; Asu = state[24];

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
            Eba ^= KeccakF_RoundConstants[round];
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
            Aba ^= KeccakF_RoundConstants[round + 1];
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
        state[ 0] = Aba; state[ 1] = Abe; state[ 2] = Abi; state[ 3] = Abo; state[ 4] = Abu;
        state[ 5] = Aga; state[ 6] = Age; state[ 7] = Agi; state[ 8] = Ago; state[ 9] = Agu;
        state[10] = Aka; state[11] = Ake; state[12] = Aki; state[13] = Ako; state[14] = Aku;
        state[15] = Ama; state[16] = Ame; state[17] = Ami; state[18] = Amo; state[19] = Amu;
        state[20] = Asa; state[21] = Ase; state[22] = Asi; state[23] = Aso; state[24] = Asu;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function keccak_inc_init(void) private pure
    {
        uint32  i;
        uint64 *s_inc = (uint64 *)shake256_context;

        //fprintf(stdout, "TRACE: keccak_inc_init()\n");
        for (i = 0; i < 25; ++i)
        {
            s_inc[i] = 0;
        }
        s_inc[25] = 0;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function keccak_inc_absorb(uint32 r, const uint8* m, uint32 mlen) public pure
    {
        uint32  i;
        uint64 *s_inc = (uint64 *)shake256_context;

        //fprintf(stdout, "TRACE: keccak_inc_absorb()\n");
        while (mlen + s_inc[25] >= r)
        {
            for (i = 0; i < r - (uint32)s_inc[25]; i++)
            {
                s_inc[(s_inc[25] + i) >> 3] ^= (uint64)m[i] << (8 * ((s_inc[25] + i) & 0x07));
            }
            mlen -= (uint32)(r - s_inc[25]);
            m += r - s_inc[25];
            s_inc[25] = 0;
            KeccakF1600_StatePermute(s_inc);
        }

        for (i = 0; i < mlen; i++)
        {
            s_inc[(s_inc[25] + i) >> 3] ^= (uint64)m[i] << (8 * ((s_inc[25] + i) & 0x07));
        }

        s_inc[25] += mlen;
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
    function keccak_inc_finalize(uint32 r, uint8 p) public pure
    {
        uint64 *s_inc = (uint64 *)shake256_context;

        //fprintf(stdout, "TRACE: keccak_inc_finalize()\n");
        s_inc[s_inc[25] >> 3] ^= (uint64)p << (8 * (s_inc[25] & 0x07));
        s_inc[(r - 1) >> 3] ^= (uint64)128 << (8 * ((r - 1) & 0x07));
        s_inc[25] = 0;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function keccak_inc_squeeze(uint8* h, uint32 outlen, uint32 r) private pure
    {
        uint64 *s_inc = (uint64 *)shake256_context;

        //fprintf(stdout, "TRACE: keccak_inc_squeeze()\n");
        uint32  i;

        for (i = 0; i < outlen && i < s_inc[25]; i++)
        {
            h[i] = (uint8)(s_inc[(r - s_inc[25] + i) >> 3] >> (8 * ((r - s_inc[25] + i) & 0x07)));
        }

        h += i;
        outlen -= i;
        s_inc[25] -= i;

        while (outlen > 0)
        {
            KeccakF1600_StatePermute(s_inc);
            for (i = 0; i < outlen && i < r; i++)
            {
                h[i] = (uint8)(s_inc[i >> 3] >> (8 * (i & 0x07)));
            }

            h += i;
            outlen -= i;
            s_inc[25] = r - i;
        }
    }

    ///////////////////////////////////////
    // Implementation: OQS_SHA3_shake256_inc
    ///////////////////////////////////////

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_init(void) public pure
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_init()\n");
        memset(shake256_context, 0, PQC_SHAKEINCCTX_BYTES);

        keccak_inc_init();
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_absorb(const uint8* input, uint32 inlen) public pure
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_absorb()\n");
        keccak_inc_absorb(SHAKE256_RATE, input, inlen);
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_finalize(void) public pure
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_finalize()\n");
        keccak_inc_finalize(SHAKE256_RATE, 0x1F);
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_squeeze(uint8* output, uint32 outlen) public pure
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_squeeze()\n");
        keccak_inc_squeeze(output, outlen, SHAKE256_RATE);
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function OQS_SHA3_shake256_inc_ctx_release(void) public pure
    {
        //fprintf(stdout, "TRACE: OQS_SHA3_shake256_inc_ctx_release()\n");
        // Blat over any sensitive data
        memset(shake256_context, 0, PQC_SHAKEINCCTX_BYTES);
    }

}
