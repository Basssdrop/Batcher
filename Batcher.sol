pragma solidity ^0.8.0;

contract BatchingContract {
    struct Transfer {
        address payable recipient;
        uint amount;
    }

    uint public constant MAX_BATCH_SIZE = 10;
    uint public constant MAX_GAS_PRICE = 500 gwei;

    Transfer[] public transfers;
    uint public nextTransferIndex;

    event TransferBatch(address payable[] recipients, uint[] amounts);

    function submitTransfer() public payable {
        require(transfers.length < MAX_BATCH_SIZE, "Batch is full");
        require(tx.gasprice <= MAX_GAS_PRICE, "Gas price too high");
        require(msg.value > 0, "Amount must be greater than 0");

        transfers.push(Transfer(payable(msg.sender), msg.value));
    }

    function batchTransfers() public {
        require(transfers.length > 0, "No transfers to batch");

        uint totalAmount = 0;
        address payable[] memory recipients = new address payable[](transfers.length);
        uint[] memory amounts = new uint[](transfers.length);

        for (uint i = 0; i < transfers.length; i++) {
            Transfer storage transfer = transfers[i];
            recipients[i] = transfer.recipient;
            amounts[i] = transfer.amount;
            totalAmount += transfer.amount;
        }

        require(address(this).balance >= totalAmount, "Insufficient funds in contract");

        emit TransferBatch(recipients, amounts);

        for (uint i = 0; i < transfers.length; i++) {
            Transfer storage transfer = transfers[i];
            transfer.recipient.transfer(transfer.amount);
        }

        delete transfers;
        nextTransferIndex = 0;
    }

    function getNextTransfer() public view returns (address, uint) {
        require(nextTransferIndex < transfers.length, "No more transfers");
        Transfer storage transfer = transfers[nextTransferIndex];
        return (transfer.recipient, transfer.amount);
    }

    function cancelTransfer() public {
        require(nextTransferIndex > 0, "No transfers to cancel");
        nextTransferIndex--;
        delete transfers[nextTransferIndex];
    }
}
