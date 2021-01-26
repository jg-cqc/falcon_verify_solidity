// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

// https://manojpramesh.github.io/solidity-cheatsheet/

//import "falcon_sha3_c.sol";
import * as falcon_sha3 from "falcon_sha3_c.sol";
//import "falcon_sha3_c.sol" as falcon_sha3;

contract Falcon
{

    uint16 constant NONCELEN = 40;

    // ====================================================================
    // Implementation
    // ====================================================================

    function do_verify ( bytes memory nonce,
                         bytes memory sigbuf,
                         uint16       sigbuflen,
                         bytes memory m,
                         uint16       mlen,
                         bytes memory pk        ) public pure  returns (int16)
    {
        //union
        //{
        //    uint8_t     b[2 * 512];
        //    uint64_t    dummy_u64;
        //} tmp;
        //struct tBigArray
        //{
        //    uint8[2 * 512] b;
        //}
        //tBigArray tmp;

        uint16[512] h;
        uint16[512] hm;
        int16[512]  sig;
        OQS_SHA3_shake256_inc_ctx  sc;

        //fprintf(stdout, "INFO: do_verify() ENTRY\n");

        ///////////////////////////////////////////////
        // Decode public key.
        if (pk[0] != 0x00 + 9)
        {
            return -1;
        }

        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_modq_decode()\n");
        uint16 sz1 = PQCLEAN_FALCON512_CLEAN_modq_decode( h, 9, pk + 1, PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES - 1);
        if (sz1 != PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES - 1)
        {
            return -1;
        }

        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_to_ntt_monty()\n");
        PQCLEAN_FALCON512_CLEAN_to_ntt_monty(h, 9);

        ///////////////////////////////////////////////
        // Decode signature.
        if (sigbuflen == 0)
        {
            return -1;
        }
        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_comp_decode()\n");
        uint16 sz2 = PQCLEAN_FALCON512_CLEAN_comp_decode(sig, 9, sigbuf, sigbuflen);
        if (sz2 != sigbuflen)
        {
            return -1;
        }

        ///////////////////////////////////////////////
        // Hash nonce + message into a vector.
        OQS_SHA3_shake256_inc_init(&sc);
        OQS_SHA3_shake256_inc_absorb(&sc, nonce, NONCELEN);
        OQS_SHA3_shake256_inc_absorb(&sc, m, mlen);
        OQS_SHA3_shake256_inc_finalize(&sc);
        PQCLEAN_FALCON512_CLEAN_hash_to_point_ct(&sc, hm, 9, tmp.b);
        OQS_SHA3_shake256_inc_ctx_release(&sc);

        ///////////////////////////////////////////////
        // Verify signature.
        //fprintf(stdout, "INFO: do_verify() calling PQCLEAN_FALCON512_CLEAN_verify_raw()\n");
        int rc = PQCLEAN_FALCON512_CLEAN_verify_raw(hm, sig, h, 9, tmp.b);
        if (!rc)
        {
            return -1;
        }

        //fprintf(stdout, "INFO: do_verify() EXIT\n");
        return 0;
    }

    function PQCLEAN_FALCON512_CLEAN_crypto_sign_verify ( bytes memory sig,
                                                        uint16       siglen,
                                                        bytes memory m,
                                                        uint16       mlen,
                                                        bytes memory pk     ) public pure  returns (int16)
    {
        if (siglen < 1 + NONCELEN) // 1 + 40
        {
            return -1;
        }

        if (sig[0] != 0x30 + 9)
        {
            return -1;
        }

        //fprintf(stdout, "INFO: PQCLEAN_FALCON512_CLEAN_crypto_sign_verify() Calling do_verify()\n");
        return do_verify(sig + 1,                // const uint8_t * nonce,
                        sig + 1 + NONCELEN,     // const uint8_t * sigbuf,
                        siglen - 1 - NONCELEN,  // uint16          sigbuflen,
                        m,                      // const uint8_t * m,
                        mlen,                   // uint16          mlen,
                        pk);                    // const uint8_t * pk)
    }
}
