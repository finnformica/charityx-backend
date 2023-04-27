// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract CauseContract {

    // admin address
    address payable admin;

    // contract address
    address payable contractAddress;

    // blcokChange wallet address
    address payable blockChange;
    uint256 feePercent = 1;

    // human-readable contract id
    string id;

    // transaction struct
    struct Transaction {
        address sender;
        uint256 amount;
        uint256 timestamp;
        uint256 blockNumber;
        uint256 gasUsed;
        uint256 transactionFee;
    }

    // incoming donations
    Transaction[] incoming;

    // outgoing funding
    Transaction[] outgoing;

    // donor proportion tracking
    mapping(address => uint256) public donorTotals;

    // endCause flag
    bool public endCause = false;

    // contract information struct
    struct ContractInfo {
        string id;
        address admin;
        Transaction[] incoming;
        Transaction[] outgoing;
        address contractAddress;
        bool endCause;
    }

    uint256 constant BASIS_POINTS = 5; // move the basic points to its own variable

    constructor(string memory _id) {
        admin = payable(msg.sender);
        contractAddress = payable(address(this));
        id = _id;
    }

    function retrieveInfo() public view returns (ContractInfo memory) {
        return ContractInfo(id, admin, incoming, outgoing, contractAddress, endCause);
    }


    uint256 transactionFee;

    function donate() public payable returns (bool) {
        require(msg.value > 0, "You must send some Ether");

        uint256 gasStart = gasleft();

        transactionFee = (msg.value*BASIS_POINTS) / 1000; // Transaction fee of 5bps (by default)
        

        blockChange.transfer(transactionFee);

        uint256 gasUsed = gasStart - gasleft();
        uint256 gasPrice = tx.gasprice;
        uint256 gasFee = gasUsed * gasPrice;

        incoming.push(Transaction(msg.sender, msg.value - transactionFee, block.timestamp, block.number, gasFee, transactionFee));

                // update donor proportion
        donorTotals[msg.sender] += msg.value;

        blockChange.transfer(transactionFee);

        return true;
}






    // function donate() public payable {
    //     require(msg.value > 0, "You must send some Ether");

    //     transactionFee = (msg.value*BASIS_POINTS) / 1000; // Transaction fee of 5bps (by default)
    //     incoming.push(Transaction(msg.sender, msg.value - transactionFee, block.timestamp, block.number, tx.gasprice, transactionFee));

    //     blockChange.transfer(transactionFee);

    //     // update donor proportion
    //     donorTotals[msg.sender] += msg.value;

    //     blockChange.transfer(transactionFee);

    // }

    function withdraw(uint256 _amount) public payable onlyAdmin {
        require(address(this).balance > _amount, "Insufficient funds for withdrawal");
        
        uint256 gasStart = gasleft();
        

        // use the transfer method to transfer the amount to the admin's address
        (bool success, ) = admin.call{value: _amount}("");
        require(success, "Withdrawal failed");

        uint256 gasUsed = gasStart - gasleft();
        uint256 gasPrice = tx.gasprice;
        uint256 gasFee = gasUsed * gasPrice;

        outgoing.push(Transaction(msg.sender, _amount, block.timestamp, block.number, gasFee, 0));
    }

    function authenticateAdmin() public view onlyAdmin returns (bool) {
        return true;
    }

    function updateAdmin(address _newAdmin) public onlyAdmin {
        admin = payable(_newAdmin);
    }

    function endCauseFunction() public onlyAdmin {
        endCause = true;
    }

    mapping(address => bool) public addressDonated;

    function distributeFunds() public onlyAdmin {
        require(endCause == true, "The cause has not ended yet");
        require(address(this).balance > 0, "The contract balance is zero");

        uint256 totalDonation = address(this).balance;

        // keep track of whether an address has already donated or not
        

        for (uint256 i = 0; i < incoming.length; i++) {
            address sender = incoming[i].sender;

            // check if the address has already donated
            if (!addressDonated[sender]) {
                uint256 proportion = donorTotals[sender] * 100 / totalDonation;
                uint256 donation = totalDonation * proportion / 100;
                if (donation > 0) {
                    (bool success, ) = sender.call{value: donation}("");
                    require(success, "Failed to distribute funds to donor");
                }

                // mark the address as having donated
                addressDonated[sender] = true;
        }
    }
}


    modifier onlyAdmin() {
        require(admin == msg.sender, "You are not the admin of this contract");
        _;
    }
}
