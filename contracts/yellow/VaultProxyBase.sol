//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import '@openzeppelin/contracts/proxy/Proxy.sol';
import '@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './VaultImplBase.sol';

/**
 * @notice Logic for the Proxy, excluding start implementation contract address, which must be hardcoded.
 * @dev ProxyBase contract was extracted from the Proxy to allow supplying start implementation address and thus ease testing.
 */
abstract contract VaultProxyBase is Proxy, ERC1967Upgrade {
    /**
     * @notice Set the address of the latest version of implementation contract, provided the first implementation contract in the versions chain. Call `initialize` on that address. Grant admin role to deployer.
     * @dev Recursively retrieve `newerImplementation` address starting with `startImplementation` supplied.
     */
    constructor(address startImplementation) {
        // Point to the first VaultImpl in the versions chain
        address newImplementation = startImplementation;
        address newerImplementation = address(0);

        while (true) {
            newerImplementation = VaultImplBase(newImplementation).getNewerImplementation();

            if (newerImplementation == address(0)) {
                break;
            }

            newImplementation = newerImplementation;
        }

        _upgradeToAndCall(
            newImplementation,
            abi.encodeWithSelector(bytes4(keccak256('initialize()'))),
            true
        );

        Address.functionDelegateCall(
            newImplementation,
            abi.encodeWithSelector(bytes4(keccak256('setupDeployerRoles()'))),
            'deployer roles not set up'
        );
    }

    /**
     * @notice Retrieve implementation contract.
     * @dev May be used by block explorers.
     * @return address Implementation contract address.
     */
    function getImplementation() external view returns (address) {
        return _implementation();
    }

    /**
     * @notice Retrieve implementation contract stored in `_IMPLEMENTATION_SLOT`. Internal method.
     * @dev Retrieve implementation contract stored in `_IMPLEMENTATION_SLOT`. Internal method.
     * @return address Implementation contract address.
     */
    function _implementation() internal view override returns (address) {
        return ERC1967Upgrade._getImplementation();
    }
}
