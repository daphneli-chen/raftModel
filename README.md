# 1950yfinal

For our final project, we modeled the Raft consensus algorithm for data replication among servers. We have five main files that model properties of different scenarios: one_candidate_election.pml, multiple_candidates.pml, split_vote.pml, log_simple_commit.pml, and log_commit_paper.pml.

one_candidate_election.pml:
	This file models an election with only one candidate, demonstrating that when there is only one candidate per election file a leader will always be elected. In our model, the nodes all start as followers with their own random index length (modeling the random timeouts of the Raft protocol) and random terms, up to 5. We then choose a candidate from these follower nodes, and hold an election for that candidate based on voting rules (do not vote for a candidate at a lower term; if terms are equivalent, do not vote for a candidate who has a shorter log). If the majority of nodes vote for the candidate then they become the new leader, and we update their term and index appropriately. 
	After the election, we determine whether a leader exists; if the candidate wasn't elected, it falls back to follower status. In this scenario, we reset and repeat the process, starting with all nodes as followers again, until a leader is elected. The ltl property for this model is that there will always eventually be one leader (i.e. a leader will always be elected when there is only one candidate per election).

multiple_candidates.pml:
	This file extends the logic of the one candidate election to model an election with two candidates (which is then extensible to 3 of 4 candidates because the pairwise interaction of the nodes remains the same). In this file we demonstrate that in an election with two candidates, there will always eventually be one leader and not two leaders.
	We start out the same way as in the one candidate election, with all nodes as followers with their own random index and term. We then choose two followers to become candidates for the election, and keep track of whether each candidate has been elected through two booleans. We then run the election with both candidates simultaneously (using an atomic sequence) so each candidate collects votes at the same time. We then count the number of leaders to ensure that only one candidate was elected. If no candidates were elected (i.e. a leader doesn't exist) we reset all nodes to follower status and repeat until a leader is found.
	The ltl property that we are proving in this file is that there will always eventually be one leader and never two leaders.

split_vote.pml:

log_simple_commit:

log_commit_paper: