module package_addr::crowdfunding_pricefeed {
	//https://docs.supra.com/oracles/data-feeds/pull-oracle
  use sui::event;
  use sui::coin::{Self, Coin};
  use sui::balance::{Self, Balance};
  use sui::sui::SUI;
	use sui::clock::Clock;
	use supra_validator::validator_v2::DkgState;
	use SupraOracle::SupraSValueFeed::OracleHolder;
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
	entry fun get_pair_price_v2(
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
