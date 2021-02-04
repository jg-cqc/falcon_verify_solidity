// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

//import "lib_falcon_common.sol";
//import "lib_falcon_vrfy_constants.sol";

//import GMb from "lib_falcon_vrfy_constants.sol";

library lib_falcon_vrfy
{
    uint32 Q = 1; // TODO: Where do I get Q
    uint32 Q0I = 1; // TODO: Where do I get Q0I
    uint32 R = 1; // TODO: Where do I get R
    uint32 R2 = 1; // TODO: Where do I get R2
    uint32[2] GMb = [1,2]; // TODO: Where do I get GMb
    uint32[2] iGMb = [1,2]; // TODO: Where do I get iGMb
    
    
    
    ////////////////////////////////////////
    // Addition modulo q. Operands must be in the 0..q-1 range.
    ////////////////////////////////////////
    function mq_add(uint32 x, uint32 y) private pure returns (uint32 result)
    {
        uint32    d;

        d = x + y - Q;
        d += Q & -(d >> 31);
        result = d;
    }

    ////////////////////////////////////////
    // Subtraction modulo q. Operands must be in the 0..q-1 range.
    ////////////////////////////////////////
    function mq_sub(uint32 x, uint32 y) private pure returns (uint32 result)
    {
         // As in mq_add(), we use a conditional addition to ensure the result is in the 0..q-1 range.
        uint32    d;

        d = x - y;
        d += Q & -(d >> 31);
        return d;
    }

    ////////////////////////////////////////
    // Division by 2 modulo q. Operand must be in the 0..q-1 range.
    ////////////////////////////////////////
    function mq_rshift1(uint32 x) private pure returns (uint32 result)
    {
        x += Q & -(x & 1);
        return (x >> 1);
    }

    ////////////////////////////////////////
    // Montgomery multiplication modulo q. If we set R = 2^16 mod q, then this function computes: x * y / R mod q
    // Operands must be in the 0..q-1 range.
    ////////////////////////////////////////
    function mq_montymul(uint32 x, uint32 y) private pure returns (uint32 result)
    {
        uint32    z;
        uint32    w;

        z = x * y;
        w = ((z * Q0I) & 0xFFFF) * Q;
        z = (z + w) >> 16;
        z -= Q;
        z += Q & -(z >> 31);
        return z;
    }

    ////////////////////////////////////////
    // Montgomery squaring (computes (x^2)/R).
    ////////////////////////////////////////
    function mq_montysqr(uint32 x) private pure returns (uint32 result)
    {
        return mq_montymul(x, x);
    }

    ////////////////////////////////////////
    // Divide x by y modulo q = 12289.
    ////////////////////////////////////////
    function mq_div_12289(uint32 x, uint32 y) private pure returns (uint32 result)
    {
    /*$off*/
        uint32    y0;
        uint32    y1;
        uint32    y2;
        uint32    y3;
        uint32    y4;
        uint32    y5;
        uint32    y6;
        uint32    y7;
        uint32    y8;
        uint32    y9;
        uint32    y10;
        uint32    y11;
        uint32    y12;
        uint32    y13;
        uint32    y14;
        uint32    y15;
        uint32    y16;
        uint32    y17;
        uint32    y18;
    /*$on*/

        y0 = mq_montymul(y, R2);
        y1 = mq_montysqr(y0);
        y2 = mq_montymul(y1, y0);
        y3 = mq_montymul(y2, y1);
        y4 = mq_montysqr(y3);
        y5 = mq_montysqr(y4);
        y6 = mq_montysqr(y5);
        y7 = mq_montysqr(y6);
        y8 = mq_montysqr(y7);
        y9 = mq_montymul(y8, y2);
        y10 = mq_montymul(y9, y8);
        y11 = mq_montysqr(y10);
        y12 = mq_montysqr(y11);
        y13 = mq_montymul(y12, y9);
        y14 = mq_montysqr(y13);
        y15 = mq_montysqr(y14);
        y16 = mq_montymul(y15, y10);
        y17 = mq_montysqr(y16);
        y18 = mq_montymul(y17, y0);

        return mq_montymul(y18, x);
    }

    ////////////////////////////////////////
    // Compute NTT on a ring element.
    ////////////////////////////////////////
    function mq_NTT(bytes memory /*uint16**/ a, uint logn) private pure
    {
        uint32  n;
        uint32  t;
        uint32  m;

        n = uint32(1) << logn;
        t = n;
        for (m = 1; m < n; m <<= 1)
        {
            uint32  ht;
            uint32  i;
            uint32  j1;

            ht = t >> 1;
            j1 = 0;
            for (i = 0; i < m; i++)
            {
                uint32 j;
                uint32 j2;
                uint32 s;

                s = GMb[m + i];
                j2 = j1 + ht;
                for (j = j1; j < j2; j++)
                {
                    uint32 u;
                    uint32 v;

                    u = a[j];
                    v = mq_montymul(a[j + ht], s);
                    a[j] = uint16(mq_add(u, v));
                    a[j + ht] = uint16(mq_sub(u, v));
                }
                j1 += t;
            }

            t = ht;
        }
    }

    ////////////////////////////////////////
    // Compute the inverse NTT on a ring element, binary case.
    ////////////////////////////////////////
    function mq_iNTT(bytes memory /*uint16**/ a, uint logn) private pure
    {
        uint32 n;
        uint32 t;
        uint32 m;
        uint32 ni;

        n = uint32(1) << logn;
        t = 1;
        m = n;
        while (m > 1)
        {
            uint32  hm;
            uint32  dt;
            uint32  i;
            uint32  j1;

            hm = m >> 1;
            dt = t << 1;
            j1 = 0;
            for (i = 0; i < hm; i++)
            {
                uint32      j;
                uint32      j2;
                uint32    s;

                j2 = j1 + t;
                s = iGMb[hm + i];
                for (j = j1; j < j2; j++)
                {
                    uint32    u;
                    uint32    v;
                    uint32    w;

                    u = a[j];
                    v = a[j + t];
                    a[j] = uint16(mq_add(u, v));
                    w = mq_sub(u, v);
                    a[j + t] = uint16(mq_montymul(w, s));
                }
                j1 += dt;
            }

            t = dt;
            m = hm;
        }

        ni = R;
        for (m = n; m > 1; m >>= 1)
        {
            ni = mq_rshift1(ni);
        }

        for (m = 0; m < n; m++)
        {
            a[m] = uint16(mq_montymul(a[m], ni));
        }
    }

    ////////////////////////////////////////
    // Convert a polynomial (mod q) to Montgomery representation.
    ////////////////////////////////////////
    function mq_poly_tomonty(bytes memory /*uint16**/ f, uint logn) private pure
    {
        uint32  u;
        uint32  n;

        n = uint32(1) << logn;
        for (u = 0; u < n; u++)
        {
            f[u] = uint16(mq_montymul(f[u], R2));
        }
    }

    ////////////////////////////////////////
    // Multiply two polynomials together (NTT representation, and using
    // a Montgomery multiplication). Result f*g is written over f.
    ////////////////////////////////////////
    function mq_poly_montymul_ntt(bytes memory /*uint16**/ f, bytes constant memory /*uint16**/ g, uint logn) private pure
    {
        uint32  u;
        uint32  n;
        /*~~~~~~*/

        n = uint32(1) << logn;
        for (u = 0; u < n; u++)
        {
            f[u] = uint16(mq_montymul(f[u], g[u]));
        }
    }

    ////////////////////////////////////////
    // Subtract polynomial g from polynomial f.
    ////////////////////////////////////////
    function mq_poly_sub(bytes memory /*uint16**/ f, bytes constant memory /*uint16**/ g, uint logn) private pure
    {
        uint32  u;
        uint32  n;
        /*~~~~~~*/

        n = uint32(1) << logn;
        for (u = 0; u < n; u++)
        {
            f[u] = uint16(mq_sub(f[u], g[u]));
        }
    }

    /* ===================================================================== */

    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_to_ntt_monty(bytes memory /*uint16**/ h, uint logn) public pure
    {
        //fprintf(stdout, "INFO: PQCLEAN_FALCON512_CLEAN_to_ntt_monty() ENTRY\n");
        mq_NTT(h, logn);
        mq_poly_tomonty(h, logn);
    }


    ////////////////////////////////////////
    //
    ////////////////////////////////////////
    function PQCLEAN_FALCON512_CLEAN_verify_raw(bytes constant memory  /*uint16**/     c0,
                                                bytes constant memory /*int16_t **/    s2,
                                                bytes constant memory  /*uint16**/     h,
                                                uint                                   logn,
                                                bytes memory workingStorage) public pure returns (int result)
    {
        uint32      u;
        uint32      n;
        bytes memory /*uint16**/   tt;

        //fprintf(stdout, "INFO: PQCLEAN_FALCON512_CLEAN_verify_raw() ENTRY\n");
        n = uint32(1) << logn;
        tt = workingStorage;  // tt = (uint16 *)workingStorage;

        // Reduce s2 elements modulo q ([0..q-1] range).
        for (u = 0; u < n; u++)
        {
            uint32    w;

            w = uint32(s2[u]);
            w += Q & -(w >> 31);
            tt[u] = uint16(w);
        }

        // Compute -s1 = s2*h - c0 mod phi mod q (in tt[]).
        mq_NTT(tt, logn);
        mq_poly_montymul_ntt(tt, h, logn);
        mq_iNTT(tt, logn);
        mq_poly_sub(tt, c0, logn);

        // Normalize -s1 elements into the [-q/2..q/2] range.
        for (u = 0; u < n; u++)
        {
            int32 w;

            w = int32(tt[u]);
            w -= int32(Q & -(((Q >> 1) - uint32(w)) >> 31));
            tt[u] = int16(w);  // ((int16 *)tt)[u] = (int16)w;
        }

        // Signature is valid if and only if the aggregate (-s1,s2) vector is short enough.
        int rc = PQCLEAN_FALCON512_CLEAN_is_short(tt, s2, logn);

        //fprintf(stdout, "INFO: PQCLEAN_FALCON512_CLEAN_verify_raw() EXIT\n");
        return rc;
    }
}
