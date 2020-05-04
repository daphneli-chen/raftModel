/*
TO-DO: COMMENT THIS
*/
#define CLUSTER_SIZE 6 //the number of nodes in the cluster
#define MAX_INDEX 4
#define FALSE 0
#define TRUE 1
#define FOLLOWER 0
#define CANDIDATE 1
#define LEADER 2


byte term[CLUSTER_SIZE]; /* term of last log index for a certain node */
byte index[CLUSTER_SIZE]; /* index of last log index for a certain node */
byte status[CLUSTER_SIZE];
bool voted[CLUSTER_SIZE];
bool oneLeader = FALSE;
bool twoLeader = FALSE;

inline Vote(voter, candidate, res) {
    if 
    :: voted[voter] -> res = FALSE;
    :: voter == candidate ->
        res = TRUE;
        voted[voter] = TRUE;
    :: term[voter] > term[candidate] -> res = FALSE; //do not vote for a candidate at a lower term
    :: term[voter] == term[candidate] && index[voter] > index[candidate] -> res = FALSE; //if terms equivalent, do not vote for a candidate who has a shorter log
    :: else ->
        res = TRUE;
        voted[voter] = TRUE;
    fi;
} 


proctype HoldElection(int candidate; bool elected) {
        term[candidate] = term[candidate] + 1; //candidates increment their term at the beginning of their election cycle
        int count = 0;
        bool res = FALSE;
        //gather votes from all nodes, candidate will vote for itself
        int i;
        for(i: 0 .. MAX_INDEX) {
            Vote(i, candidate, res);
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
            term[candidate] = term[candidate] + 1; //leader is now in a higher term
            index[candidate] = index[candidate] + 1; //adding a new entry for the new term
        :: else -> elected = FALSE;
        fi;
} 

inline CountLeaders(res1, res2) {
    int count = 0;
    for(i: 0 .. MAX_INDEX) {
        if
        :: status[i] == LEADER -> count = count + 1;
        :: else -> skip;
        fi;
    }

    if
    :: count == 1 ->
        res1 = TRUE;
        res2 = FALSE;
    :: count == 2 ->
        res1 = FALSE;
        res2 = TRUE;
    :: else ->
        res1 = FALSE;
        res2 = TRUE;
    fi;
}

active proctype main() {
    int i;
    for(i: 0 .. MAX_INDEX) { //all nodes start as followers
        status[i] = FOLLOWER; 
        byte random1;
	select (random1: 1 .. 11);
        index[i] = random1; // each log has certain index length from length 1 to 11
        byte random2;
	select (random2: 1 .. 6);
	term[i] = 0; //modeling with 5 possible terms, so trace doesn't take too long
        voted[i] = FALSE;
    }
    bool leaderExists = FALSE;
    do
    :: !leaderExists ->
        int j;
        for(j: 0 .. MAX_INDEX) { //since the terms and indices of the nodes are all randomized, going through one by one is choosing a candidate 'randomly' like having random timeouts
            int candidate1 = j;
            int candidate2 = MAX_INDEX - j;
            status[candidate1] = CANDIDATE;
            status[candidate2] = CANDIDATE; //choose the other candidate because this will never coincide in a cluster size of 5
            voted[candidate1] = TRUE;
            voted[candidate2] = TRUE; //they will vote for themselves so overall since there are two of them votes don't matter, they just cannot vote for the other
            bool elected1 = FALSE;
            bool elected2 = FALSE;
            int vot;
            for(vot: 0 .. MAX_INDEX) {
                voted[vot] = FALSE;
            }
            atomic {
                run HoldElection(candidate1, elected1);
                run HoldElection(candidate2, elected2);
            }
            if
            :: elected1 || elected2 -> 
                leaderExists = TRUE;
                break;
            :: elected1 && elected2 -> 
                leaderExists = TRUE;
                oneLeader = FALSE; //this may be unnecessary? basically if this happens this is BAD
                break;
            :: else -> status[j] = FOLLOWER; //candidate will fall back to leader upon failed election
            fi;

            if 
            :: !leaderExists -> //resetting for the next loop
                int k;
                for (k: 0 .. MAX_INDEX) { //all nodes start as followers
                    status[k] = FOLLOWER; 
                }
            :: else -> skip;
            fi;
        }
    :: else -> 
        CountLeaders(oneLeader, twoLeader);
        break;
    od;
}

ltl one_leader {
    always(eventually(oneLeader == TRUE) && (twoLeader == FALSE));
    //check if this is ok
}
