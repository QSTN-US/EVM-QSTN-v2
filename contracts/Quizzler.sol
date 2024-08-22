// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title A Quizzler contract for creating and managing surveys with rewards
/// @notice This contract allows for the creation, funding, and management of surveys and their rewards
contract Quizzler is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    /// @notice Address used as gas station for the server's manager wallet
    address public gasStation;

    /// @notice Address used as owner for the gas station account
    address public gasOwner;

    /// @notice Tracks manager permissions for addresses
    mapping(address => bool) public managers;
    /// @notice Stores survey data by survey ID
    mapping(string => SurveyStruct) public surveys;
    /// @notice Users rewarded for participating in surveys
    mapping(string => mapping(address => bool)) public surveysUsersRewarded;
    /// @notice Records used proof tokens to prevent reuse
    mapping(bytes32 => bool) public proofTokens;

    /// @notice Structure to store survey information
    struct SurveyStruct {
        address surveyCreator;
        uint256 participantsLimit;
        uint256 rewardAmount;
        uint256 participantsRewarded;
        bytes32 surveyHash;
        bool isCanceled;
    }

    /// @notice Emitted when a survey is created
    event SurveyCreated(
        string indexed surveyId,
        address indexed creator,
        uint256 participantsLimit,
        uint256 rewardAmount,
        bytes32 surveyHash
    );
    /// @notice Emitted when a survey is funded
    event SurveyFunded(
        string indexed surveyId,
        address indexed creator,
        uint256 fundingAmount
    );
    /// @notice Emitted when a reward is paid to a participant
    event RewardPaid(
        address indexed participant,
        string indexed surveyId,
        uint256 amount
    );
    /// @notice Emitted when a survey is finished
    event SurveyFinished(string indexed surveyId);
    /// @notice Emitted when a survey is canceled
    event SurveyCanceled(string indexed surveyId);
    /// @notice Emitted when a manager's status is updated
    event UpdateManager(address indexed manager, bool status);

    /// @notice Ensures only managers can call a function
    modifier onlyManager() {
        require(
            managers[msg.sender],
            "Quizzler: only manager or owner can call this function"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Fallback function that reverts any Ether sent to the contract
    receive() external payable {
        revert("Quizzler: Uncaught receive error");
    }

    /// @notice Initializes the contract setting up initial roles and states
    fallback() external payable {
        revert("Quizzler: Uncaught fallback error");
    }

    function initialize() public initializer {
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);
        managers[msg.sender] = true;
    }

    /// @notice Sets or unsets an address as a manager
    /// @param _manager Address of the manager
    /// @param _status Boolean representing the desired manager status
    function setManager(address _manager, bool _status) external onlyOwner {
        require(
            _manager != address(0),
            "PrivateStaking: invalid manager address"
        );

        managers[_manager] = _status;

        emit UpdateManager(_manager, _status);
    }

    /// @notice Allows the owner to specify the gas station address
    /// @param _gasStation Address of the gas station
    /// @param _gasOwner Address of the gas station owner
    function setGasStation(
        address _gasStation,
        address _gasOwner
    ) external onlyOwner {
        require(
            _gasStation != address(0),
            "PrivateStaking: invalid gas station address"
        );
        require(
            _gasOwner != address(0),
            "PrivateStaking: invalid gas owner address"
        );

        gasStation = _gasStation;
        gasOwner = _gasOwner;
    }

    /// @notice Retrieves the amount required to fully fund a survey
    /// @param _surveyId Unique ID of the survey
    /// @return amountToFund The amount of funds required to pay out all potential rewards
    function getSurveyAmountToFund(
        string memory _surveyId
    ) public view returns (uint256 amountToFund) {
        amountToFund =
            surveys[_surveyId].participantsLimit *
            surveys[_surveyId].rewardAmount;
    }

    /// @notice Calculates the total reward amount paid for a specific survey
    /// @param _surveyId Unique ID of the survey
    /// @return amountPayded Total amount of rewards paid to participants
    function getSurveysRewardsAmountPayded(
        string memory _surveyId
    ) public view returns (uint256 amountPayded) {
        amountPayded =
            surveys[_surveyId].participantsRewarded *
            surveys[_surveyId].rewardAmount;
    }

    /// @notice Returns detailed information about a survey
    /// @param _surveyId The unique identifier of the survey
    /// @return surveyCreator The creator of the survey
    /// @return participantsLimit The maximum number of participants allowed
    /// @return rewardAmount The reward amount per participant
    /// @return participantsRewarded The number of participants already rewarded
    /// @return amountToFund The remaining amount needed to fully fund the survey
    /// @return surveyHash The unique hash of the survey for verification
    /// @return isCanceled Whether the survey has been canceled
    function getSurvey(
        string memory _surveyId
    )
        external
        view
        returns (
            address surveyCreator,
            uint256 participantsLimit,
            uint256 rewardAmount,
            uint256 participantsRewarded,
            uint256 amountToFund,
            bytes32 surveyHash,
            bool isCanceled
        )
    {
        surveyCreator = surveys[_surveyId].surveyCreator;
        participantsLimit = surveys[_surveyId].participantsLimit;
        rewardAmount = surveys[_surveyId].rewardAmount;
        participantsRewarded = surveys[_surveyId].participantsRewarded;
        surveyHash = surveys[_surveyId].surveyHash;
        isCanceled = surveys[_surveyId].isCanceled;
        amountToFund = getSurveyAmountToFund(_surveyId);
    }

    /// @notice Create a new survey
    /// @param _surveyId The unique identifier for the new survey
    /// @param _participantsLimit The max number of participants allowed
    /// @param _rewardAmount The amount of reward for each participant
    /// @param _surveyHash A unique hash representing the survey
    /// @dev Emits a SurveyCreated event upon successful creation
    function _createSurvey(
        string memory _surveyId,
        uint256 _participantsLimit,
        uint256 _rewardAmount,
        bytes32 _surveyHash
    ) internal returns (bool result) {
        require(
            surveys[_surveyId].surveyCreator == address(0),
            "Quizzler: survey already exists"
        );

        surveys[_surveyId] = SurveyStruct({
            surveyCreator: msg.sender,
            participantsLimit: _participantsLimit,
            rewardAmount: _rewardAmount,
            participantsRewarded: 0,
            surveyHash: _surveyHash,
            isCanceled: false
        });

        emit SurveyCreated(
            _surveyId,
            msg.sender,
            _participantsLimit,
            _rewardAmount,
            _surveyHash
        );

        return true;
    }

    /// @notice Generates a proof for survey creating
    /// @param _token Unique token for the transaction
    /// @param _timeToExpire Timestamp until which the proof is valid
    /// @param _owner The creator of the survey
    /// @param _surveyId The survey identifier
    /// @param _participantsLimit The max number of participants allowed
    /// @param _rewardAmount The amount of reward for each participant
    /// @param _surveyHash A unique hash representing the survey
    /// @param _amountToGasStation Amount to be transferred to the gas station
    /// @return message Generated message hash
    function createProof(
        bytes32 _token,
        uint256 _timeToExpire,
        address _owner,
        string memory _surveyId,
        uint256 _participantsLimit,
        uint256 _rewardAmount,
        bytes32 _surveyHash,
        uint256 _amountToGasStation
    ) public view returns (bytes32 message) {
        if (proofTokens[_token]) {
            message = bytes32(0);
        } else {
            message = keccak256(
                abi.encodePacked(
                    getChainID(),
                    _token,
                    _timeToExpire,
                    _owner,
                    _surveyId,
                    _participantsLimit,
                    _rewardAmount,
                    _surveyHash,
                    _amountToGasStation
                )
            );
        }
    }

    /// @notice Funds a survey verifying all conditions are met
    function createSurvey(
        bytes memory _signature,
        bytes32 _token,
        uint256 _timeToExpire,
        address _owner,
        string memory _surveyId,
        uint256 _participantsLimit,
        uint256 _rewardAmount,
        bytes32 _surveyHash,
        uint256 _amountToGasStation
    ) external payable nonReentrant {
        require(
            msg.sender == _owner,
            "Quizzler: only survey creator can fund the survey"
        );
        bytes32 message = createProof(
            _token,
            _timeToExpire,
            _owner,
            _surveyId,
            _participantsLimit,
            _rewardAmount,
            _surveyHash,
            _amountToGasStation
        );

        address signer = preAuthValidations(
            message,
            _token,
            _timeToExpire,
            _signature
        );

        require(
            _createSurvey(
                _surveyId,
                _participantsLimit,
                _rewardAmount,
                _surveyHash
            ),
            "Quizzler: survey creation failed"
        );

        require(managers[signer], "Quizzler: invalid signer");

        uint256 amountToSurvey = _participantsLimit * _rewardAmount;

        require(
            msg.value == amountToSurvey + _amountToGasStation,
            "Quizzler: invalid trx value"
        );
        require(
            amountToSurvey == getSurveyAmountToFund(_surveyId),
            "Quizzler: invalid reward amount"
        );

        (bool success, ) = payable(gasStation).call{value: _amountToGasStation}(
            ""
        );

        require(success, "Transfer failed");

        emit SurveyFunded(_surveyId, msg.sender, msg.value);
    }

    /// @notice Generates a proof for survey cancellation
    function cancelProof(
        bytes32 _token,
        uint256 _timeToExpire,
        string memory _surveyId
    ) public view returns (bytes32 message) {
        if (proofTokens[_token]) {
            message = bytes32(0);
        } else {
            message = keccak256(
                abi.encodePacked(getChainID(), _token, _timeToExpire, _surveyId)
            );
        }
    }

    /// @notice Cancels a survey and refunds the unspent funds
    function cancelSurvey(
        bytes memory _signature,
        bytes32 _token,
        uint256 _timeToExpire,
        string memory _surveyId
    ) external nonReentrant {
        require(
            surveys[_surveyId].surveyCreator != address(0),
            "Quizzler: survey does not exist"
        );
        require(
            !surveys[_surveyId].isCanceled,
            "Quizzler: survey is already canceled"
        );
        require(
            msg.sender == surveys[_surveyId].surveyCreator ||
                managers[msg.sender],
            "Quizzler: only survey creator or manager can cancel the survey"
        );
        require(
            surveys[_surveyId].participantsLimit >
                surveys[_surveyId].participantsRewarded,
            "Quizzler: all participants have been rewarded"
        );

        bytes32 message = cancelProof(_token, _timeToExpire, _surveyId);

        address signer = preAuthValidations(
            message,
            _token,
            _timeToExpire,
            _signature
        );

        require(managers[signer], "Quizzler: invalid signer");

        surveys[_surveyId].isCanceled = true;

        uint256 returnAmount = getSurveyAmountToFund(_surveyId) -
            getSurveysRewardsAmountPayded(_surveyId);

        (bool success, ) = payable(surveys[_surveyId].surveyCreator).call{
            value: returnAmount
        }("");

        require(success, "Transfer failed");

        emit SurveyCanceled(_surveyId);
    }

    /// @notice Generates a proof for rewarding
    function rewardProof(
        bytes32 _token,
        uint256 _timeToExpire,
        string[] memory _surveyIds,
        address[] memory _participantsEncoded
    ) public view returns (bytes32 message) {
        if (proofTokens[_token]) {
            message = bytes32(0);
        } else {
            message = keccak256(
                abi.encodePacked(
                    getChainID(),
                    _token,
                    _timeToExpire,
                    _surveyIds.length,
                    _participantsEncoded.length
                )
            );
        }
    }

    /// @notice Distributes rewards to survey participants
    function payRewards(
        bytes memory _signature,
        bytes32 _token,
        uint256 _timeToExpire,
        string[] memory _surveyIds,
        address[] memory _participantsEncoded
    ) external nonReentrant {
        require(
            _surveyIds.length == _participantsEncoded.length,
            "Quizzler: Mismatch between survey IDs and participant data lengths"
        );

        bytes32 message = rewardProof(
            _token,
            _timeToExpire,
            _surveyIds,
            _participantsEncoded
        );

        address signer = preAuthValidations(
            message,
            _token,
            _timeToExpire,
            _signature
        );

        require(managers[signer], "Quizzler: invalid signer");

        for (uint256 j = 0; j < _participantsEncoded.length; j++) {
            string memory surveyId = _surveyIds[j];
            require(
                !surveys[surveyId].isCanceled,
                "Quizzler: Survey has been canceled"
            );
            require(
                surveys[surveyId].participantsRewarded <
                    surveys[surveyId].participantsLimit,
                "Quizzler: All participants have been rewarded"
            );
            require(
                !surveysUsersRewarded[surveyId][_participantsEncoded[j]],
                "Quizzler: User has already been rewarded"
            );

            (bool success, ) = payable(_participantsEncoded[j]).call{
                value: surveys[surveyId].rewardAmount
            }("");

            require(success, "Transfer failed");
            surveys[surveyId].participantsRewarded++;
            surveysUsersRewarded[surveyId][_participantsEncoded[j]] = true;

            emit RewardPaid(
                _participantsEncoded[j],
                surveyId,
                surveys[surveyId].rewardAmount
            );

            if (
                surveys[surveyId].participantsRewarded ==
                surveys[surveyId].participantsLimit
            ) {
                emit SurveyFinished(surveyId);
            }
        }
    }

    /// @notice Validates the message and signature
    /// @param _message The message that the user signed
    /// @param _token The unique token for each delegated function
    /// @param _timeToExpire The time to expire the token
    /// @param _signature Signature
    /// @return address Signer of the message
    function preAuthValidations(
        bytes32 _message,
        bytes32 _token,
        uint256 _timeToExpire,
        bytes memory _signature
    ) public returns (address) {
        require(_message != bytes32(0), "Quizzler: invalid message hash");
        require(
            !proofTokens[_token],
            "Quizzler: proof token has already been used"
        );
        require(
            block.timestamp <= _timeToExpire,
            "Quizzler: proof token has expired"
        );

        address signer = getSigner(_message, _signature);
        require(signer != address(0), "Access: Zero address not allowed");

        proofTokens[_token] = true;

        return signer;
    }

    /// @notice Find the signer
    /// @param message The message that the user signed
    /// @param signature Signature
    /// @return address Signer of the message
    function getSigner(
        bytes32 message,
        bytes memory signature
    ) public pure returns (address) {
        message = MessageHashUtils.toEthSignedMessageHash(message);
        address signer = ECDSA.recover(message, signature);
        return signer;
    }

    /// @notice Get the ID of the executing chain
    /// @return uint256 value
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
