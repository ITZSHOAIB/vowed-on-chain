// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract VowedOnChain {
    // The struct that defines a spouse
    struct Spouse {
        address partner; // The address of the partner
        uint256 weddingDate; // The date of the wedding
        MarriageStatus status; // The status of the marriage
        MarriageStatus proposedStatus; // The proposed status of the marriage
        address proposer; // The address of the proposer
        uint256 giftBalance; // The gift balance of the spouse
    }

    // The mapping of spouses to their data
    mapping(address => Spouse) public spouses;
    // The status of the marriage
    enum MarriageStatus {
        Single,
        Engaged,
        Married,
        Divorced
    }

    // The event that is emitted when a status change occurs
    event StatusChanged(
        address indexed spouse1,
        address indexed spouse2,
        MarriageStatus oldStatus,
        MarriageStatus newStatus,
        uint256 date
    );
    // The event that is emitted when someone sends a gift to the contract
    event Gifted(
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );
    // // The event that is emitted when a spouse proposes a status change
    // event Proposed(address indexed proposer, MarriageStatus proposedStatus);
    // // The event that is emitted when a spouse accepts a status change
    // event Accepted(address indexed accepter, MarriageStatus acceptedStatus);

    // The modifier that checks if the caller is the partner of the given address
    modifier onlyPartnerOf(address _partner) {
        require(
            spouses[msg.sender].partner == _partner,
            "Only the partner of the given address can call this function."
        );
        _;
    }

    // The modifier that checks if the marriage status is as expected
    modifier onlyStatus(MarriageStatus _status) {
        require(
            spouses[msg.sender].status == _status,
            "The marriage status is not as expected."
        );
        _;
    }

    modifier onlyOtherThan(MarriageStatus _status) {
        require(
            spouses[msg.sender].status != _status,
            "The proposed status is the same as the current status."
        );
        _;
    }

    // The constructor that sets the initial status of the caller
    constructor() {
        spouses[msg.sender].status = MarriageStatus.Single;
    }

    // The function that allows a single person to get engaged with another single person
    function getEngaged(
        address _partner
    ) external onlyStatus(MarriageStatus.Single) onlyPartnerOf(address(0)) {
        require(
            spouses[_partner].status == MarriageStatus.Single,
            "The partner is not single."
        );
        require(
            spouses[_partner].partner == address(0),
            "The partner is already engaged with someone else."
        );
        spouses[msg.sender].partner = _partner;
        spouses[_partner].partner = msg.sender;
        spouses[msg.sender].status = MarriageStatus.Engaged;
        spouses[_partner].status = MarriageStatus.Engaged;
        emit StatusChanged(
            msg.sender,
            _partner,
            MarriageStatus.Single,
            MarriageStatus.Engaged,
            block.timestamp
        );
    }

    function updateProposedStatus(MarriageStatus _status) private {
        spouses[msg.sender].proposedStatus = _status;
        spouses[msg.sender].proposer = msg.sender;
    }

    // The function that allows an engaged person to propose marriage to their partner
    function proposeMarriage()
        external
        onlyStatus(MarriageStatus.Engaged)
        onlyOtherThan(MarriageStatus.Married)
    {
        updateProposedStatus(MarriageStatus.Married);
    }

    // The function that allows a married person to propose divorce to their partner
    function proposeDivorce()
        external
        onlyStatus(MarriageStatus.Married)
        onlyOtherThan(MarriageStatus.Divorced)
    {
        updateProposedStatus(MarriageStatus.Divorced);
    }

    // The function that allows a spouse to accept a status change from their partner
    function acceptStatus()
        external
        onlyPartnerOf(spouses[spouses[msg.sender].partner].proposer)
    {
        require(
            spouses[spouses[msg.sender].partner].proposedStatus !=
                spouses[msg.sender].status,
            "The proposed status is the same as the current status."
        );
        MarriageStatus oldStatus = spouses[msg.sender].status;
        MarriageStatus newStatus = spouses[spouses[msg.sender].partner]
            .proposedStatus;
        spouses[msg.sender].status = newStatus;
        spouses[spouses[msg.sender].partner].status = newStatus;
        if (newStatus == MarriageStatus.Married) {
            spouses[msg.sender].weddingDate = block.timestamp;
            spouses[spouses[msg.sender].partner].weddingDate = block.timestamp;
        }
        emit StatusChanged(
            msg.sender,
            spouses[msg.sender].partner,
            oldStatus,
            newStatus,
            block.timestamp
        );
    }

    // The function that allows a divorced person to reset their status to single
    function resetStatus() external onlyStatus(MarriageStatus.Divorced) {
        spouses[msg.sender].partner = address(0);
        spouses[msg.sender].status = MarriageStatus.Single;
    }

    // The function that allows anyone to send a gift to a spouse directly
    function sendGift(address _receiver) external payable {
        require(msg.value > 0, "The gift amount must be positive.");
        require(
            spouses[_receiver].status != MarriageStatus.Single,
            "The receiver must be engaged or married."
        );
        spouses[_receiver].giftBalance += msg.value;
        emit Gifted(msg.sender, _receiver, msg.value);
    }

    // The function that allows a spouse to withdraw their gift balance
    function withdrawGifts() external {
        uint256 giftBalance = spouses[msg.sender].giftBalance;
        require(giftBalance > 0, "The gift balance must be positive.");
        spouses[msg.sender].giftBalance = 0;
        payable(msg.sender).transfer(giftBalance);
    }

    // The function that returns the gift balance of a spouse
    function getGiftBalance() external view returns (uint256) {
        return spouses[msg.sender].giftBalance;
    }
}
