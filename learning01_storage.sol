// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;

/// @title Storage
// @dev Store & retrieve value in a variable
contract Storage
{
    uint256 m_number;

    //constructor()
    //{
    //    m_number = 0;
    //}

    constructor(uint256 _number)
    {
        m_number = _number;
    }

    /// @dev Store value in variable
    // @param num value to store
    function store(uint256 _number) public
    {
        m_number = _number;
    }

    /// @dev Return value
    // @return value of 'number'
    function retrieve() public view returns (uint256)
    {
        return m_number;
    }
}

