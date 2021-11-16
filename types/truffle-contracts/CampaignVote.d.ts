/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import BN from "bn.js";
import { EventData, PastEventOptions } from "web3-eth-contract";

export interface CampaignVoteContract
  extends Truffle.Contract<CampaignVoteInstance> {
  "new"(meta?: Truffle.TransactionDetails): Promise<CampaignVoteInstance>;
}

export interface Paused {
  name: "Paused";
  args: {
    account: string;
    0: string;
  };
}

export interface Unpaused {
  name: "Unpaused";
  args: {
    account: string;
    0: string;
  };
}

export interface VoteCancelled {
  name: "VoteCancelled";
  args: {
    voteId: BN;
    requestId: BN;
    support: BN;
    0: BN;
    1: BN;
    2: BN;
  };
}

export interface Voted {
  name: "Voted";
  args: {
    voteId: BN;
    requestId: BN;
    support: BN;
    0: BN;
    1: BN;
    2: BN;
  };
}

type AllEvents = Paused | Unpaused | VoteCancelled | Voted;

export interface CampaignVoteInstance extends Truffle.ContractInstance {
  campaignContract(txDetails?: Truffle.TransactionDetails): Promise<string>;

  campaignFactoryContract(
    txDetails?: Truffle.TransactionDetails
  ): Promise<string>;

  campaignID(txDetails?: Truffle.TransactionDetails): Promise<BN>;

  /**
   * Returns true if the contract is paused, and false otherwise.
   */
  paused(txDetails?: Truffle.TransactionDetails): Promise<boolean>;

  voteId(
    arg0: string,
    arg1: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<BN>;

  votes(
    arg0: number | BN | string,
    txDetails?: Truffle.TransactionDetails
  ): Promise<{ 0: BN; 1: BN; 2: boolean; 3: string }>;

  __CampaignVote_init: {
    (
      _campaignFactory: string,
      _campaign: string,
      _campaignId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _campaignFactory: string,
      _campaign: string,
      _campaignId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _campaignFactory: string,
      _campaign: string,
      _campaignId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _campaignFactory: string,
      _campaign: string,
      _campaignId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  /**
   * Approvers only method which approves spending request issued by the campaign manager or factory
   * @param _requestId ID of request being voted on
   * @param _support An integer of 0 for against, 1 for in-favor, and 2 for abstain
   */
  voteOnRequest: {
    (
      _requestId: number | BN | string,
      _support: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _requestId: number | BN | string,
      _support: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _requestId: number | BN | string,
      _support: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _requestId: number | BN | string,
      _support: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  /**
   * Approvers only method which cancels initial vote on a request
   * @param _requestId ID of request being voted on
   */
  cancelVote: {
    (
      _requestId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<Truffle.TransactionResponse<AllEvents>>;
    call(
      _requestId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<void>;
    sendTransaction(
      _requestId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;
    estimateGas(
      _requestId: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<number>;
  };

  methods: {
    campaignContract(txDetails?: Truffle.TransactionDetails): Promise<string>;

    campaignFactoryContract(
      txDetails?: Truffle.TransactionDetails
    ): Promise<string>;

    campaignID(txDetails?: Truffle.TransactionDetails): Promise<BN>;

    /**
     * Returns true if the contract is paused, and false otherwise.
     */
    paused(txDetails?: Truffle.TransactionDetails): Promise<boolean>;

    voteId(
      arg0: string,
      arg1: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<BN>;

    votes(
      arg0: number | BN | string,
      txDetails?: Truffle.TransactionDetails
    ): Promise<{ 0: BN; 1: BN; 2: boolean; 3: string }>;

    __CampaignVote_init: {
      (
        _campaignFactory: string,
        _campaign: string,
        _campaignId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _campaignFactory: string,
        _campaign: string,
        _campaignId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _campaignFactory: string,
        _campaign: string,
        _campaignId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _campaignFactory: string,
        _campaign: string,
        _campaignId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    /**
     * Approvers only method which approves spending request issued by the campaign manager or factory
     * @param _requestId ID of request being voted on
     * @param _support An integer of 0 for against, 1 for in-favor, and 2 for abstain
     */
    voteOnRequest: {
      (
        _requestId: number | BN | string,
        _support: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _requestId: number | BN | string,
        _support: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _requestId: number | BN | string,
        _support: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _requestId: number | BN | string,
        _support: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };

    /**
     * Approvers only method which cancels initial vote on a request
     * @param _requestId ID of request being voted on
     */
    cancelVote: {
      (
        _requestId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<Truffle.TransactionResponse<AllEvents>>;
      call(
        _requestId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<void>;
      sendTransaction(
        _requestId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<string>;
      estimateGas(
        _requestId: number | BN | string,
        txDetails?: Truffle.TransactionDetails
      ): Promise<number>;
    };
  };

  getPastEvents(event: string): Promise<EventData[]>;
  getPastEvents(
    event: string,
    options: PastEventOptions,
    callback: (error: Error, event: EventData) => void
  ): Promise<EventData[]>;
  getPastEvents(event: string, options: PastEventOptions): Promise<EventData[]>;
  getPastEvents(
    event: string,
    callback: (error: Error, event: EventData) => void
  ): Promise<EventData[]>;
}