// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

// Revenue Cut Calculators return how much (from 0 to 100) someone will get based on how long the interval of time between the two dates (arguments) is.
interface RevenueCutCalculator {
   function getResult(uint256, uint256) external view returns(uint256);
}


// Basic contract that scales linearly between two dates - begins counting from the moment the key is transfered
contract BasicRevenueCut is RevenueCutCalculator {
   
    // Minimum Royalties possible
    uint256 public min;

    // Maximum Royalties possible
    uint256 public max;

    // How long between minimum and maximum (in seconds)
    uint256 public timeInterval;

   constructor(uint256 _timeInterval, uint256 _min, uint256 _max) {
      timeInterval = _timeInterval;
      min = _min;
      max = _max;
   }

   // Returns how many royalties a person will get based on how long the interval of time between the two dates (arguments) is.
   function getResult(uint256 _beginning, uint256 _end) public view override returns (uint256) {
        uint256 timeDifference = _end - _beginning;
        uint256 result = min + (timeDifference * (max - min) / timeInterval);
        
        if (result > max) { // Can't exceed max
            result = max;
        }

        return result;
   }
}