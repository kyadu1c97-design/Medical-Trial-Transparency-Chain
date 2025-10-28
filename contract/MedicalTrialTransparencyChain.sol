// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MedicalTrialTransparencyChain {
    
    struct Trial {
        uint256 trialId;
        string trialName;
        address researcher;
        string methodology;
        uint256 startDate;
        uint256 endDate;
        bool isCompleted;
        bool resultsPublished;
    }
    
    struct Result {
        uint256 trialId;
        string outcome; // "positive", "negative", "neutral"
        string dataHash; // IPFS hash of full results
        uint256 publishDate;
        bool verified;
    }
    
    mapping(uint256 => Trial) public trials;
    mapping(uint256 => Result) public trialResults;
    mapping(address => bool) public verifiedResearchers;
    
    uint256 public trialCount;
    address public admin;
    
    event TrialRegistered(uint256 indexed trialId, string trialName, address researcher);
    event ResultsPublished(uint256 indexed trialId, string outcome, string dataHash);
    event ResultVerified(uint256 indexed trialId, address verifier);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyVerifiedResearcher() {
        require(verifiedResearchers[msg.sender], "Only verified researchers can register trials");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        verifiedResearchers[msg.sender] = true; // Admin is a verified researcher
    }
    
    // Core Function 1: Register a new clinical trial
    function registerTrial(
        string memory _trialName,
        string memory _methodology,
        uint256 _startDate,
        uint256 _endDate
    ) public onlyVerifiedResearcher returns (uint256) {
        require(_endDate > _startDate, "End date must be after start date");
        
        trialCount++;
        
        trials[trialCount] = Trial({
            trialId: trialCount,
            trialName: _trialName,
            researcher: msg.sender,
            methodology: _methodology,
            startDate: _startDate,
            endDate: _endDate,
            isCompleted: false,
            resultsPublished: false
        });
        
        emit TrialRegistered(trialCount, _trialName, msg.sender);
        return trialCount;
    }
    
    // Core Function 2: Publish trial results (positive, negative, or neutral)
    function publishResults(
        uint256 _trialId,
        string memory _outcome,
        string memory _dataHash
    ) public {
        require(_trialId > 0 && _trialId <= trialCount, "Invalid trial ID");
        Trial storage trial = trials[_trialId];
        require(msg.sender == trial.researcher, "Only the trial researcher can publish results");
        require(!trial.resultsPublished, "Results already published");
        require(block.timestamp >= trial.endDate, "Trial has not ended yet");
        
        trial.isCompleted = true;
        trial.resultsPublished = true;
        
        trialResults[_trialId] = Result({
            trialId: _trialId,
            outcome: _outcome,
            dataHash: _dataHash,
            publishDate: block.timestamp,
            verified: false
        });
        
        emit ResultsPublished(_trialId, _outcome, _dataHash);
    }
    
    // Core Function 3: Verify published results (by independent reviewers)
    function verifyResults(uint256 _trialId) public onlyVerifiedResearcher {
        require(_trialId > 0 && _trialId <= trialCount, "Invalid trial ID");
        require(trials[_trialId].resultsPublished, "Results not yet published");
        require(msg.sender != trials[_trialId].researcher, "Researcher cannot verify their own results");
        
        Result storage result = trialResults[_trialId];
        result.verified = true;
        
        emit ResultVerified(_trialId, msg.sender);
    }
    
    // Admin function: Add verified researchers
    function addVerifiedResearcher(address _researcher) public onlyAdmin {
        verifiedResearchers[_researcher] = true;
    }
    
    // Admin function: Remove verified researchers
    function removeVerifiedResearcher(address _researcher) public onlyAdmin {
        verifiedResearchers[_researcher] = false;
    }
    
    // View function: Get trial details
    function getTrial(uint256 _trialId) public view returns (
        string memory trialName,
        address researcher,
        string memory methodology,
        uint256 startDate,
        uint256 endDate,
        bool isCompleted,
        bool resultsPublished
    ) {
        require(_trialId > 0 && _trialId <= trialCount, "Invalid trial ID");
        Trial memory trial = trials[_trialId];
        return (
            trial.trialName,
            trial.researcher,
            trial.methodology,
            trial.startDate,
            trial.endDate,
            trial.isCompleted,
            trial.resultsPublished
        );
    }
    
    // View function: Get trial results
    function getResults(uint256 _trialId) public view returns (
        string memory outcome,
        string memory dataHash,
        uint256 publishDate,
        bool verified
    ) {
        require(_trialId > 0 && _trialId <= trialCount, "Invalid trial ID");
        require(trials[_trialId].resultsPublished, "Results not yet published");
        Result memory result = trialResults[_trialId];
        return (
            result.outcome,
            result.dataHash,
            result.publishDate,
            result.verified
        );
    }
}
