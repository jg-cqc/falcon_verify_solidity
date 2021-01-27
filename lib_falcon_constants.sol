// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

library lib_falcon_constants
{
    ////////////////////////////////////////
    //
    ////////////////////////////////////////

    // Falcon Error codes
    int16 constant FALCON_ERR_OK       = 0;  // Success
    int16 constant FALCON_ERR_SUCCESS  = 0;  // Success
    int16 constant FALCON_ERR_RANDOM   = -1;
    int16 constant FALCON_ERR_SIZE     = -2;
    int16 constant FALCON_ERR_FORMAT   = -3; // Returned when decoding of an external object (public key, private key, signature) fails.
    int16 constant FALCON_ERR_BADSIG   = -4; // Returned when verifying a signature, the signature is validly encoded, but its value does not match the provided message and public key.
    int16 constant FALCON_ERR_BADARG   = -5; // Returned when a provided parameter is not in a valid range.
    int16 constant FALCON_ERR_INTERNAL = -6;


    // Falcon Signature formats
    uint8 constant FALCON_SIG_INFERRED   = 0; // Signature format is inferred from the signature header byte; In this case, the signature is malleable (since a signature value can be transcoded to other formats).
    uint8 constant FALCON_SIG_COMPRESSED = 1; // Variable-size signature. This format produces the most compact signatures on average, but the signature size may vary depending on private key, signed data, and random seed.
    uint8 constant FALCON_SIG_PADDED     = 2; // Fixed-size signature. Same as compressed, but includes padding to a known fixed size (FALCON_SIG_PADDED_SIZE).
                                            // With this format, the signature generation loops until an appropriate signature size is achieved (such looping is uncommon) and adds the padding bytes;
                                            // the verification functions check the presence and contents of the padding bytes.
    uint8 constant FALCON_SIG_CT         = 3; // Fixed-size format amenable to constant-time implementation. All formats allow constant-time code with regard to the private key;
                                            // the 'CT' format also prevents information about the signature value and the signed data hash to leak through timing-based side channels (this feature is rarely needed).

}
