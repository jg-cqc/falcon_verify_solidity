// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//import "lib_falcon_pqclean.sol";
//import "lib_falcon_dataset_from_kestrel.sol"

contract con_falcon_test_sig
{
    //#define TEST_HAPPY_PATH
    //#define TEST_UNHAPPY_PATH

    int8 constant EXIT_SUCCESS = 0;
    int8 constant EXIT_FAILURE = -1;
    
    // OQS_STATUS;
    int8 constant OQS_ERROR                       = -1;
    int8 constant OQS_SUCCESS                     = 0;
    int8 constant OQS_EXTERNAL_LIB_ERROR_OPENSSL  = 50;

    //#ifdef TEST_UNHAPPY_PATH
    function CorruptSomeBits(bytes memory /* unsigned char **/ pData, uint16 cbData) private pure
    {
        // TODO - Any corruption will do
        //if (cbData >   0) { pData[  0] = ~(pData[  0]); }
        //if (cbData >  10) { pData[ 10] = ~(pData[ 10]); }
        //if (cbData > 100) { pData[100] = ~(pData[100]); }
    }
    //#endif


    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function main() public pure returns (int16)
    {
        uint8[]   public_key;
        uint32    public_key_len = 0;
        uint8[]   message;
        uint32    message_len = 0;
        uint8[]   signature;
        uint32    signature_len;
        int16     rc;
        int8      ret = EXIT_FAILURE;

        //printf("*** ================================================================================\n");
        //printf("*** Sample computation for signature Falcon-512\n");
        //printf("*** ================================================================================\n");

        do
        {
            public_key     = g_pubKey;
            public_key_len = g_pubKeyLen;
            message        = g_message;
            message_len    = g_messageLen;
            signature      = g_signature;
            signature_len  = g_signatureLen;

            if (public_key_len != PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES)
            {
                //fprintf(stderr, "ERROR: Length of Public key (%lu) not as expected (%u)\n", public_key_len, PQCLEAN_FALCON512_CLEAN_CRYPTO_PUBLICKEYBYTES);
                ret = EXIT_FAILURE;
                break;
            }

    //#ifdef TEST_HAPPY_PATH
            //fprintf(stdout, "-------------------------------------------------------------------------------------\n");
            //fprintf(stdout, "*** Calling PQCLEAN_FALCON512_CLEAN_crypto_sign_verify()\n");
            rc = PQCLEAN_FALCON512_CLEAN_crypto_sign_verify(signature, signature_len, message, message_len, public_key);
            if (rc != OQS_SUCCESS)
            {
                //fprintf(stderr, "ERROR: PQCLEAN_FALCON512_CLEAN_crypto_sign_verify failed\n");
                ret = EXIT_FAILURE;
                break;
            }
    //#endif

    //#ifdef TEST_UNHAPPY_PATH
            //fprintf(stdout, "*** -------------------------------------------------------------------------------------\n");
            //fprintf(stdout, "*** Modify the signature to invalidate it\n");
            CorruptSomeBits(signature, signature_len); // Modify the signature in order to invalidate it and force a failure
            //fprintf(stdout, "*** Calling PQCLEAN_FALCON512_CLEAN_crypto_sign_verify()\n");
            rc = PQCLEAN_FALCON512_CLEAN_crypto_sign_verify(signature, signature_len, message, message_len, public_key);
            if (rc != OQS_ERROR)
            {
                //fprintf(stderr, "ERROR: PQCLEAN_FALCON512_CLEAN_crypto_sign_verify should have failed!\n");
                ret = EXIT_FAILURE;
                break;
            }
    //#endif

            //fprintf(stdout, "*** All tests pass OK\n");
            ret = EXIT_SUCCESS;
            break;
        } while (0);

        //fprintf(stdout, "*** Cleanup...\n");
        return ret;
    }
}

