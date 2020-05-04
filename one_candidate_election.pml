/*
demonstrates that when when elections happen with one candidate per election cycle a leader will always be elected 
*/
#define CLUSTER_SIZE 5 //the number of nodes in the cluster
#define MAX_INDEX 4
#define FALSE 0
#define TRUE 1
#define FOLLOWER 0
#define CANDIDATE 1
#define LEADER 2


byte term[CLUSTER_SIZE]; /* term of last log index for a certain node */
byte index[CLUSTER_SIZE]; /* index of last log index for a certain node */
byte status[CLUSTER_SIZE];
bool oneLeader = FALSE;

inline Vote(voter, candidate, res) {
    d_step {
        bool sameNode = voter == candidate;
        bool greaterTerm = term[voter] > term[candidate];
        bool equalTermGreaterIndex = (term[voter] == term[candidate]) && index[voter] > index[candidate];
        if 
        :: sameNode -> res = TRUE; //we will always vote for ourselves in a one candidate election
        :: greaterTerm -> res = FALSE; //do not vote for a candidate at a lower term
        :: equalTermGreaterIndex -> res = FALSE; //if terms equivalent, do not vote for a candidate who has a shorter log
        :: !sameNode && !greaterTerm && !equalTermGreaterIndex -> res = TRUE;
        fi;
    }
} 


inline HoldElection(candidate, elected) {
        d_step {
            term[candidate] = term[candidate] + 1; //candidates increment their term at the beginning of their election cycle
            int count = 0;
            bool res = FALSE;
            //gather votes from all nodes, candidate will vote for itself
            int i;
            for(i: 0 .. MAX_INDEX) {
                Vote(i, candidate, res);
                if 
                :: res -> count = count + 1;
                :: !res -> skip;
                fi;
            }

            //count votes and figure out who was elected
            if
            :: count > (CLUSTER_SIZE/2 + 1) -> 
                elected = TRUE;
                status[candidate] = LEADER;
                term[candidate] = term[candidate] + 1; //leader is now in a higher term
                index[candidate] = index[candidate] + 1; //adding a new entry for the new term
            :: count <= (CLUSTER_SIZE/2 + 1) -> elected = FALSE;
            fi;
        }
} 

inline OneLeader(res) {
    d_step {
	int i;
        int count = 0;
        for(i: 0 .. MAX_INDEX) {
            if
            :: status[i] == LEADER -> count = count + 1;
            :: status[i] != LEADER -> skip;
            fi;
        }

        if
        :: count == 1 -> res = TRUE;
        :: count != 1 -> res = FALSE;
        fi;
    }
}

active proctype main() {
    d_step {
        int i;
        for(i: 0 .. MAX_INDEX) { //all nodes start as followers
            status[i] = FOLLOWER;
            byte random1;
            select (random1: 1 .. 11);
            index[i] = random1; //each log has certain index length from length 1 to 11
            byte random2;
            select (random2 : 1 .. 6);
            term[i] = random2; //modeling with 5 possible terms, so trace doesn't take too long
        }
    }
    bool leaderExists = FALSE;
    do
    :: !leaderExists ->
        int j;
        for(j: 0 .. MAX_INDEX) { //since the terms and indices of the nodes are all randomized, going through one by one is choosing a candidate 'randomly' like having random timeouts
            status[j] = CANDIDATE;
            bool elected = FALSE;
            HoldElection(j, elected);
            if
            :: elected -> 
                leaderExists = TRUE;
                break;
            :: !elected -> status[j] = FOLLOWER; //candidate will fall back to follower upon failed election
            fi;

            if 
            :: !leaderExists -> //resetting for the next loop
                int k;
                for (k: 0 .. MAX_INDEX) { //all nodes start as followers
                    status[k] = FOLLOWER; 
                }
            :: leaderExists -> skip;
            fi;
        }
    :: leaderExists -> 
        OneLeader(oneLeader);
        break;
    od;
}

ltl one_leader {
    always (eventually (oneLeader == TRUE)); //check if this is ok)
}
