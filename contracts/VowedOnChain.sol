// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract VowedOnChain {
    // The address of the first spouse
    address public spouse1;

    // The address of the second spouse
    address public spouse2;

    // The date of the wedding
    uint256 public weddingDate;

    // The status of the marriage
    enum MarriageStatus {
        Single,
        Engaged,
        Married,
        Divorced
    }
    MarriageStatus public status;
    // The proposed status of the marriage
    MarriageStatus public proposedStatus;
    // The address of the spouse who proposed the status change
    address public proposer;

    // The event that is emitted when the couple gets engaged
    event Engaged(address indexed spouse1, address indexed spouse2);
    // The event that is emitted when the couple gets married
    event Married(
        address indexed spouse1,
        address indexed spouse2,
        uint256 date
    );
    // The event that is emitted when the couple gets divorced
    event Divorced(
        address indexed spouse1,
        address indexed spouse2,
        uint256 date
    );
    // The event that is emitted when someone sends a gift to the contract
    event Gifted(address indexed sender, uint256 amount);
    // The event that is emitted when a spouse proposes a status change
    event Proposed(address indexed proposer, MarriageStatus proposedStatus);
    // The event that is emitted when a spouse accepts a status change
    event Accepted(address indexed accepter, MarriageStatus acceptedStatus);

    // The modifier that checks if the caller is one of the spouses
    modifier onlySpouse() {
        require(
            msg.sender == spouse1 || msg.sender == spouse2,
            "Only a spouse can call this function."
        );
        _;
    }

    // The modifier that checks if the marriage status is as expected
    modifier onlyStatus(MarriageStatus _status) {
        require(status == _status, "The marriage status is not as expected.");
        _;
    }

    modifier onlyOtherThan(MarriageStatus _status) {
        require(
            status != _status,
            "The proposed status is the same as the current status."
        );
        _;
    }

    // The constructor that sets the owner and the initial status
    constructor() {
        spouse1 = msg.sender;
        status = MarriageStatus.Single;
    }

    // The function that allows the owner to set the spouses
    function getEngaged(address _spouse2)
        external
        onlySpouse
        onlyStatus(MarriageStatus.Single)
    {
        spouse2 = _spouse2;
        status = MarriageStatus.Engaged;
        emit Engaged(spouse1, spouse2);
    }

    function updateProposedStatus(MarriageStatus _status) private {
        proposedStatus = _status;
        proposer = msg.sender;
        emit Proposed(proposer, proposedStatus);
    }

    // The function that allows a spouse to propose a status change
    function proposeMarriage()
        external
        onlySpouse
        onlyStatus(MarriageStatus.Engaged)
        onlyOtherThan(MarriageStatus.Married)
    {
        updateProposedStatus(MarriageStatus.Married);
    }

    function proposeDivorce()
        external
        onlySpouse
        onlyStatus(MarriageStatus.Married)
        onlyOtherThan(MarriageStatus.Divorced)
    {
        updateProposedStatus(MarriageStatus.Divorced);
    }

    // The function that allows a spouse to accept a status change
    function acceptStatus() external onlySpouse {
        require(proposer != address(0), "No proposal has been made.");
        require(
            msg.sender != proposer,
            "The proposer cannot accept their own proposal."
        );
        require(
            proposedStatus != status,
            "The proposed status is the same as the current status."
        );
        status = proposedStatus;
        if (status == MarriageStatus.Married) {
            weddingDate = block.timestamp;
            emit Married(spouse1, spouse2, weddingDate);
        } else if (status == MarriageStatus.Divorced) {
            emit Divorced(spouse1, spouse2, block.timestamp);
        }
        emit Accepted(msg.sender, status);
        proposer = address(0);
    }

    // The function that allows anyone to send gifts to the contract
    function sendGift() external payable {
        require(msg.value > 0, "The gift amount must be positive.");
        emit Gifted(msg.sender, msg.value);
    }

    // The function that allows the owner to withdraw the gifts from the contract
    function withdrawGifts() external onlySpouse {
        require(address(this).balance > 0, "The contract balance is zero.");
        payable(msg.sender).transfer(address(this).balance);
    }
}
