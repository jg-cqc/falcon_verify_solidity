// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

// https://manojpramesh.github.io/solidity-cheatsheet/

//import "falcon_sha3_c.sol";
import * as falcon_sha3 from "falcon_sha3_c.sol";
//import "falcon_sha3_c.sol" as falcon_sha3;

library lib_falcon_pqclean
{
    ////////////////////////////////////////
    //
    ////////////////////////////////////////

    uint16 constant NONCELEN = 40;

    // ====================================================================
    // Implementation
    // ====================================================================

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function do_verify ( bytes memory nonce,
                         bytes memory sigbuf,
                         uint16       sigbuflen,
                         bytes memory m,
                         uint16       mlen,
                         bytes memory pk        ) public pure returns (int16)
    {
        uint8[2 * 512] workingStorage; // array of 1024 bytes
        uint16[512] h;
        uint16[512] hm;
        int16[512]  sig;
        uint16 sz1;
        uint16 sz2;
        int16 rc;

        //fprintf(stdout, "INFO: do_verify() ENTRY\n");

        ///////////////////////////////////////////////
        // Validate params
        if (pk[0] != 0x00 + 9)
        {
            return -3;
        }
        if (sigbuflen == 0)
        {
            return -5;
        }

        ///////////////////////////////////////////////
        // Decode public key.
        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_modq_decode()\n");
        sz1 = PQCLEAN_FALCON512_CLEAN_modq_decode( h, 9, pk + 1, PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES - 1);
        if (sz1 != PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES - 1)
        {
            return -1;
        }

        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_to_ntt_monty()\n");
        PQCLEAN_FALCON512_CLEAN_to_ntt_monty(h, 9);

        ///////////////////////////////////////////////
        // Decode signature.
        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_comp_decode()\n");
        sz2 = PQCLEAN_FALCON512_CLEAN_comp_decode(sig, 9, sigbuf, sigbuflen);
        if (sz2 != sigbuflen)
        {
            return -6;
        }

        ///////////////////////////////////////////////
        // Hash nonce + message into a vector.
        OQS_SHA3_shake256_inc_init();
        OQS_SHA3_shake256_inc_absorb(nonce, NONCELEN);
        OQS_SHA3_shake256_inc_absorb(m, mlen);
        OQS_SHA3_shake256_inc_finalize();
        PQCLEAN_FALCON512_CLEAN_hash_to_point_ct(hm, 9, workingStorage);
        OQS_SHA3_shake256_inc_ctx_release();

        ///////////////////////////////////////////////
        // Verify signature.
        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_verify_raw()\n");
        rc = PQCLEAN_FALCON512_CLEAN_verify_raw(hm, sig, h, 9, workingStorage);
        if (!rc)
        {
            return -7;
        }

        //fprintf(stdout, "INFO: do_verify() EXIT\n");
        return 0;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_crypto_sign_verify ( bytes memory sig,
                                                          uint16       siglen,
                                                          bytes memory m,
                                                          uint16       mlen,
                                                          bytes memory pk     ) public pure  returns (int16)
    {
        if (siglen < 1 + NONCELEN) // 1 + 40
        {
            return -11;
        }

        if (sig[0] != 0x30 + 9)
        {
            return -12;
        }

        const uint8 *nonce      = sig + 1;
        const uint8 *sigbuf     = sig + 1 + NONCELEN;
        const uint32   sigbuflen  = siglen - 1 - NONCELEN;

        //fprintf(stdout, "INFO: PQCLEAN_FALCON512_CLEAN_crypto_sign_verify() Calling do_verify()\n");
        return do_verify(nonce, sigbuf, sigbuflen, m, mlen, pk);
    }
}
