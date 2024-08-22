const BigNumber = require("bignumber.js");

function compareNumbers(
  referenceNumber,
  actualNumber,
  decimals = 18,
  tolerance = 1
) {
  const divisor = new BigNumber(10).pow(decimals);
  const reference = new BigNumber(referenceNumber.toString()).dividedBy(
    divisor
  );
  const actual = new BigNumber(actualNumber.toString()).dividedBy(divisor);

  const difference = reference.minus(actual).abs();

  if (!difference.isLessThanOrEqualTo(new BigNumber(tolerance))) {
    console.log(
      `Reference: ${reference.toString()}, Actual: ${actual.toString()}, Difference: ${difference.toString()}`
    );
  }

  return difference.isLessThanOrEqualTo(new BigNumber(tolerance));
}

const useCoeff = (numb, coeff, decimals = 18) => {
  const divisor = new BigNumber(10).pow(decimals);
  const coefficient = new BigNumber(coeff.toString());
  const number = new BigNumber(numb.toString())
    .multipliedBy(coefficient)
    .multipliedBy(divisor);
  return number.toFixed();
};

module.exports = { compareNumbers, useCoeff };
