package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `TransactionAsyncTests.cs`. Awaited transaction scopes over a running database. */
class TransactionAsyncTests extends TestCase {
	static final Reason = "Transaction: not ported";

	function testCommits_everything_the_awaited_body_wrote() {
		Assert.skip(Reason);
	}

	function testRolls_back_everything_when_the_awaited_body_throws() {
		Assert.skip(Reason);
	}

	function testIt_returns_what_the_body_produced() {
		Assert.skip(Reason);
	}

	function testThe_transaction_does_not_outlive_the_call() {
		Assert.skip(Reason);
	}

	function testA_body_may_commit_early_and_carry_on() {
		Assert.skip(Reason);
	}

	function testA_body_may_roll_back_without_raising() {
		Assert.skip(Reason);
	}

	function testA_nested_awaited_scope_joins_the_outer_one() {
		Assert.skip(Reason);
	}

	function testSynchronous_statements_join_it_too() {
		Assert.skip(Reason);
	}
}
