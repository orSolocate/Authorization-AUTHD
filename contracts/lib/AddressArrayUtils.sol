// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library AddressArrayUtils
{
    function popAtIndex(address[] storage addr_array, uint index) internal
    {
        require(index < addr_array.length, "Index out of bounds");
        addr_array[index] = addr_array[addr_array.length -1];
        addr_array.pop();
    }

    function removeAddressFromArray(address[] storage addr_array, address addr) internal
    {
        uint index = addr_array.length;
        for (uint i = 0; i < addr_array.length; i++)
        {
            if (addr_array[i] == addr)
            {
                index = i;
                break;
            }
        }
        if (index != addr_array.length)
        {
            popAtIndex(addr_array, index);
        }
    }
}
