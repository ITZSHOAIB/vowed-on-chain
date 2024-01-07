// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract VowedOnChain {
    // The struct that defines a marriage
    struct Marriage {
        address spouse1; // The address of the first spouse
        address spouse2; // The address of the second spouse
        uint256 weddingDate; // The date of the wedding
        MarriageStatus status; // The status of the marriage
        MarriageStatus proposedStatus; // The proposed status of the marriage
        address proposer; // The address of the proposer
        uint256 giftBalance; // Balance of sent gifts
    }

    // The mapping of marriage ids to marriages
    mapping(uint256 => Marriage) public marriages;

    // The mapping of spouse addresses to marriage ids
    mapping(address => uint256) public spouseToMarriage;

    // The status of the marriage
    enum MarriageStatus {
        Single,
        Engaged,
        Married,
        Divorced
    }

    // The event that is emitted when a status change occurs
    event StatusChanged(
        uint256 indexed marriageID,
        address indexed spouse1,
        address indexed spouse2,
        MarriageStatus oldStatus,
        MarriageStatus newStatus,
        uint256 date
    );
    // The event that is emitted when someone sends a gift to the contract
    event Gifted(
        address indexed sender,
        uint256 indexed marriageID,
        uint256 amount
    );

    // The modifier that checks if the caller is one of the spouses in the marriage
    modifier onlySpouse() {
        uint256 _marriageID = spouseToMarriage[msg.sender];
        require(
            msg.sender == marriages[_marriageID].spouse1 ||
                msg.sender == marriages[_marriageID].spouse2,
            "Only a spouse in the marriage can call this function."
        );
        _;
    }

    // The modifier that checks if the marriage status is as expected
    modifier onlyStatus(MarriageStatus _status) {
        require(
            marriages[spouseToMarriage[msg.sender]].status == _status,
            "The marriage status is not as expected."
        );
        _;
    }

    modifier onlyOtherThan(MarriageStatus _status) {
        require(
            marriages[spouseToMarriage[msg.sender]].status != _status,
            "The proposed status is the same as the current status."
        );
        _;
    }

    // The constructor that sets the initial status of the caller
    constructor() {
        // Create a dummy marriage with id 0 for single people
        marriages[0] = Marriage({
            spouse1: address(0),
            spouse2: address(0),
            weddingDate: 0,
            status: MarriageStatus.Single,
            proposedStatus: MarriageStatus.Single,
            proposer: address(0),
            giftBalance: 0
        });
    }

    // The function that allows a single person to get engaged with another single person
    function getEngaged(
        address _partner
    ) external onlyStatus(MarriageStatus.Single) {
        require(
            marriages[spouseToMarriage[_partner]].status ==
                MarriageStatus.Single,
            "The partner is not single."
        );
        // Generate a new marriage id
        uint256 marriageID = uint256(
            keccak256(abi.encodePacked(msg.sender, _partner, block.number))
        );
        // Create a new marriage with the id and the spouses
        marriages[marriageID] = Marriage({
            spouse1: msg.sender,
            spouse2: _partner,
            weddingDate: 0,
            status: MarriageStatus.Engaged,
            proposedStatus: MarriageStatus.Engaged,
            proposer: address(0),
            giftBalance: 0
        });
        // Assign the spouses to the new marriage
        spouseToMarriage[msg.sender] = marriageID;
        spouseToMarriage[_partner] = marriageID;
        emit StatusChanged(
            marriageID,
            msg.sender,
            _partner,
            MarriageStatus.Single,
            MarriageStatus.Engaged,
            block.timestamp
        );
    }

    function updateProposedStatus(MarriageStatus _status) private {
        uint256 _marriageID = spouseToMarriage[msg.sender];
        marriages[_marriageID].proposedStatus = _status;
        marriages[_marriageID].proposer = msg.sender;
    }

    // The function that allows an engaged person to propose marriage to their partner
    function proposeMarriage()
        external
        onlySpouse
        onlyStatus(MarriageStatus.Engaged)
        onlyOtherThan(MarriageStatus.Married)
    {
        updateProposedStatus(MarriageStatus.Married);
    }

    // The function that allows a married person to propose divorce to their partner
    function proposeDivorce()
        external
        onlySpouse
        onlyStatus(MarriageStatus.Married)
        onlyOtherThan(MarriageStatus.Divorced)
    {
        updateProposedStatus(MarriageStatus.Divorced);
    }

    // The function that allows a spouse to accept a status change from their partner
    function acceptStatus() external onlySpouse {
        uint256 _marriageID = spouseToMarriage[msg.sender];
        require(
            marriages[_marriageID].proposer != address(0),
            "No proposal has been made."
        );
        require(
            msg.sender != marriages[_marriageID].proposer,
            "The proposer cannot accept their own proposal."
        );
        require(
            marriages[_marriageID].proposedStatus !=
                marriages[_marriageID].status,
            "The proposed status is the same as the current status."
        );
        MarriageStatus oldStatus = marriages[_marriageID].status;
        MarriageStatus newStatus = marriages[_marriageID].proposedStatus;
        marriages[_marriageID].status = newStatus;
        if (newStatus == MarriageStatus.Married) {
            marriages[_marriageID].weddingDate = block.timestamp;
        }
        emit StatusChanged(
            _marriageID,
            marriages[_marriageID].spouse1,
            marriages[_marriageID].spouse2,
            oldStatus,
            newStatus,
            block.timestamp
        );
    }

    // The function that allows a divorced person to reset their status to single
    function resetStatus()
        external
        onlySpouse
        onlyStatus(MarriageStatus.Divorced)
    {
        // Assign the spouse to the dummy marriage
        spouseToMarriage[msg.sender] = 0;
    }

    // The function that allows anyone to send a gift to a marriage
    function sendGift(uint256 _marriageID) external payable {
        require(msg.value > 0, "The gift amount must be positive.");
        require(
            marriages[_marriageID].status == MarriageStatus.Married,
            "The marriage must be engaged or married."
        );
        marriages[_marriageID].giftBalance += msg.value;
        emit Gifted(msg.sender, _marriageID, msg.value);
    }

    // The function that allows a spouse to withdraw their gift balance
    function withdrawGifts() external onlySpouse {
        uint256 _marriageID = spouseToMarriage[msg.sender];
        uint256 giftBalance = marriages[_marriageID].giftBalance;
        require(giftBalance > 0, "The gift balance must be positive.");
        marriages[_marriageID].giftBalance = 0;
        payable(msg.sender).transfer(giftBalance);
    }

    // The function that returns the gift balance of a spouse
    function getGiftBalance() external view onlySpouse returns (uint256) {
        return marriages[spouseToMarriage[msg.sender]].giftBalance;
    }
}
