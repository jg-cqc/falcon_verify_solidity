// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

library lib_falcon_codec
{
    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_modq_decode(bytes memory /*uint16 **/ x, uint16 logn, bytes memory /*const void**/ in, uint32 max_in_len)  public pure returns (int32)
    {
        uint32          n;
        uint32          in_len;
        uint32          u;
        const uint8*  buf;
        uint32        acc;
        int             acc_len;

        n = (uint32)1 << logn;
        in_len = ((n * 14) + 7) >> 3;
        if (in_len > max_in_len)
        {
            return 0;
        }

        buf = in;
        acc = 0;
        acc_len = 0;
        u = 0;
        while (u < n)
        {
            acc = (acc << 8) | (*buf++);
            acc_len += 8;
            if (acc_len >= 14)
            {
                unsigned    w;
                /*~~~~~~~~~~*/

                acc_len -= 14;
                w = (acc >> acc_len) & 0x3FFF;
                if (w >= 12289)
                {
                    return 0;
                }

                x[u++] = (uint16)w;
            }
        }

        if ((acc & (((uint32)1 << acc_len) - 1)) != 0)
        {
            return 0;
        }

        return in_len;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_comp_decode(bytes memory /*int16_t**/ x, unsigned logn, bytes memory /*const void**/ in, uint32 max_in_len) public pure returns (int32)
    {
        const uint8*  buf;
        uint32          n;
        uint32          u;
        uint32          v;
        uint32        acc;
        unsigned        acc_len;

        n = (uint32)1 << logn;
        buf = in;
        acc = 0;
        acc_len = 0;
        v = 0;
        for (u = 0; u < n; u++)
        {
            unsigned    b;
            unsigned    s;
            unsigned    m;

            if (v >= max_in_len)
            {
                return 0;
            }

            acc = (acc << 8) | (uint32)buf[v++];
            b = acc >> acc_len;
            s = b & 128;
            m = b & 127;

            for (;;)
            {
                if (acc_len == 0)
                {
                    if (v >= max_in_len)
                    {
                        return 0;
                    }
                    acc = (acc << 8) | (uint32)buf[v++];
                    acc_len = 8;
                }

                acc_len--;
                if (((acc >> acc_len) & 1) != 0)
                {
                    break;
                }

                m += 128;
                if (m > 2047)
                {
                    return 0;
                }
            }
            x[u] = (int16_t)(s ? - (int)m : (int)m);
        }
        return v;
    }
}
