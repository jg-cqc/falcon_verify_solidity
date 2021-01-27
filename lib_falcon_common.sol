// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.0;

library lib_falcon_common
{
    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_hash_to_point_ct(bytes memory /*uint16**/ x, unsigned logn, uint8* workingStorage) public pure
    {
        static const uint16   overtab[] = { 0, /* unused */ 65, 67, 71, 77, 86, 100, 122, 154, 205, 287 };
        unsigned                n;
        unsigned                n2;
        unsigned                u;
        unsigned                m;
        unsigned                p;
        unsigned                over;
        bytes memory /*uint16**/ tt1;
        uint16 tt2[63];

        fprintf(stdout, "INFO: PQCLEAN_FALCON512_CLEAN_hash_to_point_ct() ENTRY\n");

        n = 1U << logn;
        n2 = n << 1;
        over = overtab[logn];
        m = n + over;
        tt1 = (uint16*)workingStorage;
        for (u = 0; u < m; u++)
        {
            uint8     buf[2];
            uint32    w;
            uint32    wr;

            OQS_SHA3_shake256_inc_squeeze(buf, sizeof buf);
            w = ((uint32)buf[0] << 8) | (uint32)buf[1];
            wr = w - ((uint32)24578 & (((w - 24578) >> 31) - 1));
            wr = wr - ((uint32)24578 & (((wr - 24578) >> 31) - 1));
            wr = wr - ((uint32)12289 & (((wr - 12289) >> 31) - 1));
            wr |= ((w - 61445) >> 31) - 1;
            if (u < n)
            {
                x[u] = (uint16)wr;
            }
            else if (u < n2)
            {
                tt1[u - n] = (uint16)wr;
            }
            else
            {
                tt2[u - n2] = (uint16)wr;
            }
        }

        for (p = 1; p <= over; p <<= 1)
        {
            unsigned    v;
            v = 0;
            for (u = 0; u < m; u++)
            {
                uint16 *s;
                uint16 *d;
                unsigned  j;
                unsigned  sv;
                unsigned  dv;
                unsigned  mk;

                if (u < n)
                {
                    s = &x[u];
                }
                else if (u < n2)
                {
                    s = &tt1[u - n];
                }
                else
                {
                    s = &tt2[u - n2];
                }

                sv = *s;
                j = u - v;
                mk = (sv >> 15) - 1U;
                v -= mk;
                if (u < p)
                {
                    continue;
                }

                if ((u - p) < n)
                {
                    d = &x[u - p];
                }
                else if ((u - p) < n2)
                {
                    d = &tt1[(u - p) - n];
                }
                else
                {
                    d = &tt2[(u - p) - n2];
                }

                dv = *d;

                mk &= -(((j & p) + 0x1FF) >> 9);
                *s = (uint16)(sv ^ (mk & (sv ^ dv)));
                *d = (uint16)(dv ^ (mk & (sv ^ dv)));
            }
        }
        fprintf(stdout, "INFO: PQCLEAN_FALCON512_CLEAN_hash_to_point_ct() EXIT\n");
    }

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_is_short(const bytes memory /*int16_t**/ s1, const bytes memory /*int16_t**/ s2, unsigned logn) public pure returns (int32)
    {
        uint32      n;
        uint32      u;
        uint32    s;
        uint32    ng;

        n = (uint32)1 << logn;
        s = 0;
        ng = 0;
        for (u = 0; u < n; u++)
        {
            int32_t z;

            z = s1[u];
            s += (uint32)(z * z);
            ng |= s;
            z = s2[u];
            s += (uint32)(z * z);
            ng |= s;
        }

        s |= -(ng >> 31);
        return s < (((uint32)7085 * (uint32)12289) >> (10 - logn));
    }
}
