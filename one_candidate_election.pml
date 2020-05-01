/*
demonstrates that when when elections happen with one candidate per election cycle a leader will always be elected 
*/
#define CLUSTER_SIZE 5 //the number of nodes in the cluster
#define FALSE 0
#define TRUE 1
#define FOLLOWER 0
#define CANDIDATE 1
#define LEADER 2


byte term[CLUSTER_SIZE]; /* term of last log index for a certain node */
byte index[CLUSTER_SIZE]; /* index of last log index for a certain node */
byte votes[CLUSTER_SIZE];
byte status[CLUSTER_SIZE];

inline Vote(voter, candidate, res) {
    if 
    :: voter == candidate -> res = TRUE; //we will always vote for ourselves in a one candidate election
    :: term[voter] > term[candidate] -> res = FALSE; //do not vote for a candidate at a lower term
    :: term[voter] == term[candidate] && index[voter] > index[candidate] -> res = FALSE; //if terms equivalent, do not vote for a candidate who has a shorter log
    else -> res = TRUE;
    fi;
} 


inline HoldElection(candidate, elected) {
    term[candidate] = term[candidate] + 1; //candidates increment their term at the beginning of their election cycle
    int count = 0;
    int i;
    //gather votes from all nodes, candidate will vote for itself 
    for (i: 0 .. CLUSTER_SIZE - 1) {
        res = FALSE
        Vote(i, candidate, res)
        if 
        :: res -> count = count + 1;
        :: else -> skip;
        fi;
    }

    //count votes and figure out who was elected
    if
    :: count > (CLUSTER_SIZE/2 + 1) -> 
        elected = TRUE;
        status[candidate] = LEADER;
        term[leader] = term[leader] + 1 //leader is now in a higher term
        index[leader] = index[leader] + 1 //adding a new entry for the new term
    :: else -> elected = FALSE;
    fi;

} 

inline OneLeader(res) {
    int count = 0
    for (i: 0 .. CLUSTER_SIZE) {
        if
        :: status[i] == LEADER -> count = count + 1;
        :: else -> skip;
        fi;
    }

    if
    :: count == 1 -> res = TRUE;
    :: else -> res = FALSE;
    fi;

}

active proctype main() {
    int i;
    for (i: 0 .. CLUSTER_SIZE) { //all nodes start as followers
        status[i] = FOLLOWER; 
    }
    leaderExists = FALSE;
    do
    :: !leaderExists ->
        for (i: 0 .. CLUSTER_SIZE) { //since the terms and indices of the nodes are all randomized, going through one by one is choosing a candidate 'randomly' like having random timeouts
            status[i] = CANDIDATE;
            bool elected = FALSE;
            HoldElection(i, elected);
            if
            :: elected -> 
                leaderExists = TRUE;
                break;
            :: else -> status[i] = FOLLOWER; //candidate will fall back to leader upon failed election
            fi;

            if 
            :: !leaderExists -> //resetting for the next loop
                int i;
                for (i: 0 .. CLUSTER_SIZE) { //all nodes start as followers
                    status[i] = FOLLOWER; 
                }
            :: else-> skip;
            fi;
        }
    }
    od;
}

ltl one_leader {
    always {
        bool one = FALSE;
        OneLeader(one);
        eventually(one == TRUE); //check if this is ok
    }
}