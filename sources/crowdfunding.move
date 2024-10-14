module package_addr::crowdfunding_pricefeed {
	//https://docs.supra.com/oracles/data-feeds/pull-oracle
  use sui::event;
  use sui::coin::{Self, Coin};
  use sui::balance::{Self, Balance};
  use sui::sui::SUI;
	use sui::clock::Clock;
	use supra_validator::validator_v2::DkgState;
	use SupraOracle::SupraSValueFeed::{get_price, OracleHolder};
	use SupraOracle::price_data_pull_v2::{verify_oracle_proof, price_data_split, MerkleRootHash};

	// ====== Errors ======
  const ENotFundOwner: u64 = 0;

  // ====== Objects ======
  public struct Fund has key {
    id: UID,
    target: u64, // in USD 
    raised: Balance<SUI>,
  }
  public struct Receipt has key {
    id: UID, 
    amount_donated: u64, // in MIST - 10^-9 of a SUI. One billion MIST equals one SUI. 
  }
  // Owner Object
  public struct FundOwnerCap has key { 
    id: UID,
    fund_id: ID, 
  }
  // ====== Events ======
  public struct TargetReached has copy, drop {
    raised_amount_sui: u128,
  }
	
  public entry fun init_fund(target: u64, ctx: &mut TxContext) {
    let fund_uid = object::new(ctx);
    let fund_id: ID = object::uid_to_inner(&fund_uid);

    let fund = Fund {
        id: fund_uid,
        target,
        raised: balance::zero(),
    };
    // send the Owner Object
    transfer::transfer(FundOwnerCap {
          id: object::new(ctx),
          fund_id: fund_id,
        }, tx_context::sender(ctx));
    // share the object so anyone can donate
    transfer::share_object(fund);
  }
	
  public entry fun donate(oracle_holder: &OracleHolder, fund: &mut Fund, gasCoinId: Coin<SUI>, ctx: &mut TxContext) {
    // get the donated amount for receipt.
    let amount_donated: u64 = coin::value(&gasCoinId);

    // add the amount to the fund's balance
    let coin_balance = coin::into_balance(gasCoinId);
    balance::join(&mut fund.raised, coin_balance);

    // get price of sui_usdt using Supra's Oracle SValueFeed: price in 18 dp, decimals, timestamp, round; pair is from https://docs.supra.com/oracles/data-feeds/data-feeds-index
    let (price, _,_,_) = get_price(oracle_holder, 90);

    // adjust price to have the same number of decimal points as SUI as price is in 18 dp
    let adjusted_price = price / 1000000000;

    // get the total raised amount so far in SUI
    let raised_amount_sui = (balance::value(&fund.raised) as u128);

    let fund_target_usd = (fund.target as u128) * 1000000000; // 9 decimal places

    // check if the fund target in USD has been reached (by the amount donated in SUI)
    if ((raised_amount_sui * adjusted_price) >= fund_target_usd) {
        event::emit(TargetReached { raised_amount_sui });
    };
    // make and send receipt NFT to the donor
    let receipt: Receipt = Receipt {
        id: object::new(ctx), 
        amount_donated,
      };
    transfer::transfer(receipt, tx_context::sender(ctx));
  }

  // withdraw funds from the fund contract, requires a fund owner capability that matches the fund id
  public entry fun withdraw_funds(cap: &FundOwnerCap, fund: &mut Fund, ctx: &mut TxContext) {
    assert!(&cap.fund_id == object::uid_as_inner(&fund.id), ENotFundOwner);

    let fund_balc: u64 = balance::value(&fund.raised);

    let sui_obj: Coin<SUI> = coin::take(&mut fund.raised, fund_balc, ctx);

    transfer::public_transfer(sui_obj, tx_context::sender(ctx));
  }

  public entry fun get_price_from_client(oracle_holder: &OracleHolder, pair_index: u32, _ctx: &TxContext):u128 {
			let (price, _,_,_) = get_price(oracle_holder, pair_index);
			price
		}
	
	// ====== PriceFeed ====== 
	// Price pair data list
	public struct PricePair has copy, drop, store  {
		pair: u32,
		price: u128,
		decimal: u16,
		round: u64,
	}
	public struct EmitPrice has copy, drop {
		price_pairs: vector<PricePair>
	}
	/// Get pair price data with verify signature
	public entry fun get_pair_price_v2(
		dkg_state: &DkgState,
		oracle_holder: &mut OracleHolder,
		merkle_root_hash: &mut MerkleRootHash,
		clock: &Clock,
		bytes: vector<u8>,
		_ctx: &mut TxContext,
	) {
		let mut price_datas = verify_oracle_proof(dkg_state, oracle_holder, merkle_root_hash, clock, bytes, _ctx);

		let mut price_pairs = vector::empty<PricePair>();
		while (!vector::is_empty(&price_datas)) {
				let price_data = vector::pop_back(&mut price_datas);
				let (cc_pair_index, cc_price, _xyz, cc_decimal, cc_round) = price_data_split(&price_data);
				
				vector::push_back(&mut price_pairs, PricePair { pair: cc_pair_index, price: cc_price, decimal: cc_decimal, round: cc_round });
		};
		event::emit(EmitPrice { price_pairs });
	}

}
