package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `TransactionTests.cs`. Transaction scopes over a running database. */
class TransactionTests extends TestCase {
	static final Reason = "Transaction: not ported";

	function testCommits_everything_the_body_wrote() {
		Assert.skip(Reason);
	}

	function testRolls_back_everything_when_the_body_throws() {
		Assert.skip(Reason);
	}

	function testReads_inside_the_body_see_the_uncommitted_writes() {
		Assert.skip(Reason);
	}

	function testReturns_the_bodys_result() {
		Assert.skip(Reason);
	}

	function testA_nested_scope_joins_the_outer_one_rather_than_committing_early() {
		Assert.skip(Reason);
	}

	function testWork_after_a_rolled_back_scope_still_commits() {
		Assert.skip(Reason);
	}

	function testA_batched_insert_inside_a_scope_is_rolled_back_with_it() {
		Assert.skip(Reason);
	}

	function testThe_body_reads_what_it_has_written() {
		Assert.skip(Reason);
	}

	function testCommitting_early_keeps_what_was_written_so_far() {
		Assert.skip(Reason);
	}

	function testRolling_back_inside_the_body_abandons_the_work() {
		Assert.skip(Reason);
	}

	function testCommitting_with_no_transaction_open_is_refused() {
		Assert.skip(Reason);
	}
}
