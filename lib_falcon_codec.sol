// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

library lib_falcon_codec
{
    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_modq_decode(bytes memory /*uint16 **/ x, uint16 logn, bytes memory /*const void**/ In, uint32 max_In_len)  public pure returns (uint32)
    {
        uint32        n;
        uint32        In_len;
        uint32        u;
        //uint8 *       buf;
        uint32        buf_ndx;
        uint32        acc;
        uint32        acc_len;

        n = uint32(1) << logn;
        In_len = ((n * 14) + 7) >> 3;
        if (In_len > max_In_len)
        {
            return 0;
        }

        //buf = In;
        buf_ndx = 0;
        acc     = 0;
        acc_len = 0;
        u       = 0;

        while (u < n)
        {
            acc = (acc << 8) | uint32(uint8(In[buf_ndx++]));   // acc = (acc << 8) | (*buf++);
            acc_len += 8;
            if (acc_len >= 14)
            {
                uint32 w;

                acc_len -= 14;
                w = (acc >> acc_len) & 0x3FFF;
                if (w >= 12289)
                {
                    return 0;
                }

                // TODO: Check me, incl endianess.
                //x[u++] = uint16(w);
                x[u*2  ] = bytes1(uint8(uint16(w) >> 8));
                x[u*2+1] = bytes1(uint8(uint16(w) & 0x00FF));
                u++;
            }
        }

        if ((acc & ((uint32(1) << acc_len) - 1)) != 0)
        {
            return 0;
        }

        return In_len;
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_comp_decode(bytes memory /*int16_t**/ x, uint32 logn, bytes memory /*const void**/ In, uint32 max_In_len) public pure returns (uint32)
    {
        //const uint8 *buf;
        uint32  buf_ndx;
        uint32  n;
        uint32  u;
        uint32  v;
        uint32  acc;
        uint    acc_len;

        n = uint32(1) << logn;
        //buf = In;
        buf_ndx = 0;
        acc = 0;
        acc_len = 0;
        v = 0;
        for (u = 0; u < n; u++)
        {
            uint b;
            uint s;
            uint m;

            if (v >= max_In_len)
            {
                return 0;
            }

            acc = (acc << 8) | uint32(uint8(In[buf_ndx++])); // acc = (acc << 8) | uint32(buf[v++]);
            b = acc >> acc_len;
            s = b & 128;
            m = b & 127;

            for (;;)
            {
                if (acc_len == 0)
                {
                    if (v >= max_In_len)
                    {
                        return 0;
                    }
                    acc = (acc << 8) | uint32(uint8(In[buf_ndx++])); // acc = (acc << 8) | uint32(buf[v++]);
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

            // TODO: Check me, incl endianess.
            //x[u] = int16(s ? -int(m) : int(m));
            int16 val = int16((s!=0) ? -int(m) : int(m));
            x[u*2  ] = bytes1(uint8(val >> 8));
            x[u*2+1] = bytes1(uint8(val & 0x00FF));
        }
        return v;
    }
}
