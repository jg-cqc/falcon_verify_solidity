// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

import './falcon_constants.sol';
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/jg-cqc/falcon_verify_solidity/blob/main/falcon_constants.sol";


/// @title Falcon
/// @author JGilmore
// The contract definition. A constructor of the same name will be automatically called on contract creation.
contract con_falcon_signature_verify
{
   // At first, an empty "address"-type variable of the name "creator". Will be set in the constructor.
    address m_creator;
    string m_algorithm;

    // ====================================================================
    // State variables
    // ====================================================================
    uint16 __stateVar1 = 0;
    uint16 __stateVar2 = 0;

    // ====================================================================
    // Implementation
    // ====================================================================

    // The constructor. It accepts a string input and saves it to the contract's "greeting" variable.
    function constuctor(string _algorithm) public
    {
        m_creator = msg.sender;
        m_algorithm = _algorithm;
    }

    function getSender() public constant returns (string)
    {
        return m_creator;
    }

    function getBlockNumber() public constant returns (uint)
    {
        return block.number;
    }

    function setAlgorithm(string _newAlgorithm) public
    {
        m_algorithm = _newAlgorithm;
    }

    function getStateVar1() public view returns (uint16)
    {
        return __stateVar1;
    }
    function getStateVar2() public view returns (uint16)
    {
        return __stateVar2;
    }
    function setSateVars(uint16 value1, uint16 value2) public payable
    {
        __stateVar1 = value1;
        __stateVar2 = value2;
    }

    function kill() public
    {
        if (msg.sender == creator)   // Only allow this action if the account sending the signal is the creator
        {
            selfdestruct(creator);   // kills this contract and sends remaining funds back to creator
        }
    }


    ///////////////////////////////////////
    // verify
    ///////////////////////////////////////
    function verify(bytes memory signature, uint8 signatureType, bytes memory pubKey, bytes memory data) public payable returns (int16)
    {
        int16 ret = 0;

        setSateVars(uint8(pubKey[0]), uint8(pubKey[1]));

        // if (signature.length == 0)
        // {
        //     return FALCON_ERR_BADARG - 10;
        // }
        // if (pubKey.length == 0)
        // {
        //     return FALCON_ERR_BADARG - 20;
        // }
        if (data.length == 0)
        {
            return FALCON_ERR_BADARG - 30;
        }

        ret = start(signature);
        if (ret < 0)
        {
            return ret;
        }

        bytes32 dataHash = keccak256(data);
        //bytes32 dataHash = sha256(data); // Dave: Testing SHA256
        if (dataHash.length == 0)
        {
            return FALCON_ERR_BADARG - 40;
        }

        ret = finish(signature, signatureType, pubKey, dataHash);
        return ret;
    }


    ///////////////////////////////////////
    // start
    ///////////////////////////////////////
    function start(bytes memory signature) private pure returns (int16)
    {
        if (signature.length < 41)
        {
            return FALCON_ERR_FORMAT - 100;
        }
        return 0;
    }

    ///////////////////////////////////////
    // finish
    ///////////////////////////////////////
    function finish(bytes memory signature, uint8 signatureType, bytes memory pubKey, bytes32 dataHash) public payable returns (int16)
    {
        // JG: Resolve compiler warning of unused arg
        dataHash = dataHash;

        if (pubKey.length == 0)
        {
            return FALCON_ERR_FORMAT - 100;
        }

        // Ensure that the most significant nybble of pubKey[0] is 0000
        if ((pubKey[0] & 0xF0) != 0x00)
        {
            return FALCON_ERR_FORMAT - 110;
        }

        // Ensure that the least significant nybble of pubKey[0] (logn) is in the range 1..10
        uint8 logn = uint8(pubKey[0] & 0x0F);
        //setSateVars(uint8(pubKey[0]), logn);
        if (logn < 1 || logn > 10)
        {
            return FALCON_ERR_FORMAT - 120;
        }

        // Ensure that the least significant nybble of signature has the same value as that of pubKey[0] above
        if (uint8(signature[0] & 0x0F) != logn)
        {
            return FALCON_ERR_BADSIG - 130;
        }

        bool ct = false;
        if (signatureType == FALCON_SIG_INFERRED)
        {
            // The 1st byte of a Falcon signature has the format b0cc1nnnn
            // FALCON_SIG_INFERRED is 0 (b00), so 0cc1 should be b0001 (1) // TODO - the 3 or 5 doesn't look right here
            byte firstNybble = signature[0] & 0xF0; // most significant nybble of signature[0]
            //if (firstNybble != 0x30 && firstNybble != 0x50)
            if (firstNybble != 0x01) // b0001
            {
                return FALCON_ERR_FORMAT - 140;
            }
            if (signature.length != signatureCtSize(logn))
            {
                return FALCON_ERR_FORMAT - 150;
            }
            ct = true;
        }
        else if (signatureType == FALCON_SIG_COMPRESSED)
        {
            // The 1st byte of a Falcon signature has the format b0cc1nnnn
            // FALCON_SIG_COMPRESSED is 1 (b01), so b0cc1 should be b0011 (3)
            byte firstNybble = signature[0] & 0xF0; // most significant nybble of signature[0]
            if (firstNybble != 0x30) // b0011
            {
                return FALCON_ERR_FORMAT - 160;
            }
        }
        else if (signatureType == FALCON_SIG_PADDED)
        {
            // The 1st byte of a Falcon signature has the format b0cc1nnnn
            // FALCON_SIG_PADDED is 2 (b10), so 0cc1 should be 0101 (5) // TODO - the 3 doesn't look right here
            byte firstNybble = signature[0] & 0xF0; // most significant nybble of signature[0]
            //if (firstNybble != 0x30)
            if (firstNybble != 0x50) // b0101
            {
                return FALCON_ERR_FORMAT - 170;
            }
            if (signature.length != signaturePaddedSize(logn))
            {
                return FALCON_ERR_FORMAT - 180;
            }
        }
        else if (signatureType == FALCON_SIG_CT)
        {
            // The 1st byte of a Falcon signature has the format b0cc1nnnn
            // FALCON_SIG_CT is 3 (b11), so 0cc1 should be b0111 (7) // TODO - the 5 doesn't look right here
            byte firstNybble = signature[0] & 0xF0; // most significant nybble of signature[0]
            //if (firstNybble != 0x50)
            if (firstNybble != 0x70) // b0111
            {
                return FALCON_ERR_FORMAT - 190;
            }
            if (signature.length != signatureCtSize(logn))
            {
                return FALCON_ERR_FORMAT - 200;
            }
            ct = true;
        }
        else
        {
            return FALCON_ERR_BADARG - 210;
        }
        uint16 expectedSize = expectedPubKeySize(logn);
        if (pubKey.length != expectedSize)
        {
            //uint16 expectedKeylen = pubKey.length;
            //uint16 expectedKeylen = expectedPubKeySize(logn);
            //uint16 expectedKeylen = (uint16(7) << (logn-2)) + 1;
            //return FALCON_ERR_FORMAT - int16(expectedKeylen);
            //setSateVars(logn, expectedSize);
            return FALCON_ERR_FORMAT - 220;
        }

        // Signature Verification code goes here

        return 0;
    }

    ///////////////////////////////////////
    // signatureCtSize
    // Signature size (in bytes) when using the CT format.
    // The size is exact.
    ///////////////////////////////////////
    function signatureCtSize(uint8 logn) private pure returns (uint16)
    {
        return ((uint16(3) << ((logn) - 1)) - ((logn) == 3?1:0) + 41);
    }

    ///////////////////////////////////////
    // signaturePaddedSize
    // Signature size (in bytes) when using the PADDED format.
    // The size is exact.
    ///////////////////////////////////////
    function signaturePaddedSize(uint8 logn) private pure returns (uint16)
    {
        return ( uint16(44) + uint16(3 * (256 >> (10 - (logn))))
                            + uint16(2 * (128 >> (10 - (logn))))
                            + uint16(3 * ( 64 >> (10 - (logn))))
                            + uint16(2 * ( 16 >> (10 - (logn))))
                            - uint16(2 * (  2 >> (10 - (logn))))
                            - uint16(8 * (  1 >> (10 - (logn)))) );
    }

    ///////////////////////////////////////
    // expectedPubKeySize
    // Public key size (in bytes). The size is exact.
    ///////////////////////////////////////
    function expectedPubKeySize(uint8 logn) private pure returns (uint16)
    {
        // return (((logn) <= 1 ? uint16(4) : (uint16(7) << ((logn) - 2))) + 1);
        uint16 pubKeySize;
        if (logn <= 1)
            pubKeySize = uint16(4) + 1;
        else
            pubKeySize = (uint16(7) << ((logn) - 2)) + 1;
        return pubKeySize;
    }
}
