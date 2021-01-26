// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

contract Keccak
{
    uint8[24] rho = [ 1,  3,  6, 10, 15, 21,
                     28, 36, 45, 55,  2, 14,
                     27, 41, 56,  8, 25, 43,
                     62, 18, 39, 61, 20, 44 ];
    uint8[24] pi = [ 10,  7, 11, 17, 18, 3,
                      5, 16,  8, 21, 24, 4,
                     15, 23, 19, 13, 12, 2,
                     20, 14, 22,  9, 6,  1 ];

    // Dave: Replaced with x86_64 values
    //uint64[24] RC = [
    //                0x1,             0x8082, 0x800000000000808a, 0x8000000080008000,
    //             0x808b,         0x80000001, 0x8000000080008081, 0x8000000000008009,
    //               0x8a,               0x88,         0x80008009, 0x8000000a,
    //         0x8000808b, 0x800000000000008b, 0x8000000000008089, 0x8000000000008003,
    // 0x8000000000008002, 0x8000000000000080,             0x800a, 0x800000008000000a,
    // 0x8000000080008081, 0x8000000000008080,         0x80000001, 0x8000000080008008
    //];

    // Dave: Optimised for x86_64
    uint64[48] RC = [
      0x00000001, 0x00000000, 0x00008082, 0x00000000,
      0x0000808A, 0x80000000, 0x80008000, 0x80000000,
      0x0000808B, 0x00000000, 0x80000001, 0x00000000,
      0x80008081, 0x80000000, 0x00008009, 0x80000000,
      0x0000008A, 0x00000000, 0x00000088, 0x00000000,
      0x80008009, 0x00000000, 0x8000000A, 0x00000000,
      0x8000808B, 0x00000000, 0x0000008B, 0x80000000,
      0x00008089, 0x80000000, 0x00008003, 0x80000000,
      0x00008002, 0x80000000, 0x00000080, 0x80000000,
      0x0000800A, 0x00000000, 0x8000000A, 0x80000000,
      0x80008081, 0x80000000, 0x00008080, 0x80000000,
      0x80000001, 0x00000000, 0x80008008, 0x80000000
    ];

    // Dave: Changed from public to external
    function keccakf(bytes memory a) public view returns (bytes memory)
    //function keccakf(bytes memory a) external view returns (bytes memory)
    {
        // This is the memory location where the input data resides.
        // first byte is for the size of the array
        // https://docs.soliditylang.org/en/v0.7.4/internals/layout_in_storage.html#bytes-and-string

        uint aPtr;
        assembly
        {
            aPtr := add(a, 32)
        }
        uint64[5] memory b;
        uint bPtr;
        assembly
        {
            bPtr := add(b, 32)
        }

        uint8 rounds = 24; // 24
        for (uint8 i = 0; i < rounds; i++)
        {
            // Theta
            for(uint8 x = 0; x < 5; x++)
            {
                for(uint8 y = 0; y < 25; y += 5)
                {
                    uint64 packedState;
                    assembly
                    {
                        packedState := mload(add(aPtr, add(x, y)))
                    }
                    b[x] ^= packedState;
                }
            }

            for(uint8 x = 0; x < 5; x++)
            {
                for(uint8 y = 0; y < 25; y += 5)
                {
                    //uint64 temp = b[0];
                    uint64 temp = b[(x + 4) % 5] ^ (((b[(x + 1) % 5]) << 1) | ((b[(x + 1) % 5]) >> (64 - 1)));
                    assembly
                    {
                        //a[x + y] ^= temp;
                        mstore(add(aPtr, add(x, y)), xor(mload(add(aPtr, add(x, y))), temp))
                    }
                }
            }

            // Rho and Pi
            uint64 t;
            assembly
            {
                //t = a[1]
                t := mload(add(aPtr, 8))
            }
            for(uint8 x = 0; x < 24; x++)
            {
                uint8 piIndex = pi[x];
                uint64 temp = (((t) << rho[x]) | ((t) >> (64 - rho[x])));
                assembly
                {
                    //b[0] = a[piIndex];
                    mstore(bPtr, mload(add(aPtr, piIndex)))
                    //a[piIndex] = temp;
                    mstore(add(aPtr, piIndex), temp)
                }
                t = b[0];
            }

            // Chi
            for(uint8 y = 0; y < 25; y += 5)
            {
                for(uint8 x = 0; x < 5; x++)
                {
                    //b[x] = a[y + x];
                    assembly
                    {
                        mstore(add(bPtr, x), mload(add(aPtr, add(y, x))))
                    }
                }
                for(uint8 x = 0; x < 5; x++)
                {
                    uint64 temp = b[x] ^ ((~b[(x + 1) % 5]) & b[(x + 2) % 5]);
                    assembly
                    {
                        //a[y + x] = temp;
                        mstore(add(aPtr, add(y, x)), temp)
                    }
                }
            }

            // Iota
            uint64 rcValue = RC[i];
            assembly
            {
                //a[0] ^= rcValue;
                mstore(aPtr, xor(mload(aPtr), rcValue))
            }
        }
        return a;
    }
}