/*
log matching property:
if any two distinct log entries have the same term number and the same index then they will store the exact same command and be identical in all the preceding entries 
simulates a leader getting a new message from a client, must send that message to all other noes and if gets a succesful reply then everyone increments commit index
if we can get 
*/
#define CLUSTER_SIZE 3
#define MAX_LOG_LENGTH 5
#define FOLLOWER 0
#define CANDIDATE 1
#define LEADER 2
#define FALSE 0
#define TRUE 1

typedef log {
    byte term[MAX_LOG_LENGTH]; //the term of the entry
    byte command[MAX_LOG_LENGTH] //what the command is
}
typedef leader {
    byte id;
    int nextIndex[CLUSTER_SIZE];
    // byte matchIndex[CLUSTER_SIZE]
}
typedef node {
    byte currentTerm;
    byte lastLogIndex;
    // byte commitIndex
}
log logs[CLUSTER_SIZE];
//byte commitIndex[CLUSTER_SIZE];
byte status[CLUSTER_SIZE];
//leader lead;
node nodes[CLUSTER_SIZE];
bool logsMatch = FALSE;


inline AppendEntries(leaderTerm, prevLogIndex, prevLogTerm, self, res) {   
    if
    :: leaderTerm < nodes[self].currentTerm -> res = FALSE;
    :: logs[self].term[prevLogIndex] != prevLogTerm -> res = FALSE;
    :: else -> res = TRUE;
    fi;

    if //if we are going to append
    :: res ->
        if 
        :: prevLogIndex < nodes[self].lastLogIndex ->
            int j; //prevlogindex is the last index where logs are consistent
            for (j: prevLogIndex + 1 .. MAX_LOG_LENGTH - 1) { //clearing all the log entries in the follower beyond prevLogIndex
                logs[self].term[j] = 0; //0 will indicate not set
                logs[self].command[j] = 0;
            }
            nodes[self].lastLogIndex = prevLogIndex;
        :: else -> skip;
        fi;

        int ind = prevLogIndex + 1;
        do 
        :: logs[lead.id].term[ind] != 0 -> //while there are logs in the leader to append, change the follower's logs to match the leaders
            logs[self].term[ind] = logs[lead.id].term[ind];
            logs[self].command[ind] = logs[lead.id].command[ind];
            nodes[self].lastLogIndex = nodes[self].lastLogIndex + 1; //increment how long your log is
        :: else -> break;
        od;

        //updating commitIndex of this node 
        // if
        // :: leaderCommit > curr.commitIndex ->
        //     if 
        //     :: leaderCommit < curr.lastLogIndex -> curr.commitIndex = leaderCommit;
        //     :: else -> curr.commitIndex = curr.lastLogIndex;
        //     fi;
        // :: else -> skip;
        // fi;
    :: else -> skip;
    fi;


}

inline appendEntryInPeer(peer, lastIndex, appended) {
    byte leadId = lead.id;
    int prevIndex = lead.nextIndex[peer];
    prevIndex = prevIndex--;
    byte prevTerm = logs[lead.id].term[prevIndex];
    // leaderCommit = leaderNode.commitIndex;
    AppendEntries(nodes[leadId].currentTerm, prevIndex, prevTerm, peer, appended);
    if
    :: !appended -> 
        lead.nextIndex[peer] = lead.nextIndex[peer] - 1;
        //check does this work?, will it alter res appropriately?
    :: else -> 
        lead.nextIndex[peer] = lastIndex + 1; //updating appropriate maps, we are now done with this peer
        appended = TRUE;
        // leader.matchIndex[peer] = lastIndex;
        // if 
        // :: lastIndex > leaderNode.commitIndex && logs[leader.id].term[lastIndex] == leader.currentTerm ->
        //     int count = 0;
        //     int i;
        //     for (i: 0 .. CLUSTER_SIZE) {
        //         if 
        //         :: leader.matchIndex[i] == lastIndex -> count = count + 1;
        //         :: else -> skip;
        //         fi;
        //     }
        //     if 
        //     :: count > (CLUSTER_SIZE/2 + 1) -> 
        //         leader.commitIndex = lastIndex
        //         res = TRUE;
        //     :: else -> skip;
        //     fi;
        // :: else res = FALSE;
    fi;


}

active proctype main() {
    //initialize logs for each node (?) - term should be ascending, length should be randomly determined, contents randomly determined
    //need to initialize where term nor command = 0 ever
    int i;
    for (i: 0.. CLUSTER_SIZE - 1) {
        status[i] = FOLLOWER;
    }
    leader lead;
    //INITIALIZATION OF THE LEADER
    status[0] = LEADER;
    logs[0].term[0] = 1; logs[0].term[1] = 1; logs[0].term[2] = 2;
    logs[0].term[3] = 2; logs[0].term[4] = 3;
    logs[0].command[0] = 5; logs[0].command[1] = 5; logs[0].command[2] = 5;
    logs[0].command[3] = 5; logs[0].command[4] = 5;
    nodes[0].lastLogIndex = 4; nodes[0].currentTerm = 3;
    lead.id = 0;
    lead.nextIndex[0] = 5; lead.nextIndex[1] = 5; lead.nextIndex[2] = 5;

    logs[1].term[0] = 1; logs[1].term[1] = 1; logs[1].term[2] = 2;
    logs[1].term[3] = 0; logs[1].term[4] = 0;
    logs[1].command[0] = 5; logs[1].command[1] = 5; logs[1].command[2] = 5;
    logs[1].command[3] = 0; logs[1].command[4] = 0;
    nodes[1].lastLogIndex = 3; nodes[1].currentTerm = 2;

    logs[2].term[0] = 1; logs[2].term[1] = 1; logs[2].term[2] = 1;
    logs[2].term[3] = 1; logs[2].term[4] = 1;
    logs[2].command[0] = 1; logs[2].command[1] = 1; logs[2].command[2] = 1;
    logs[2].command[3] = 1; logs[2].command[4] = 1;
    nodes[2].lastLogIndex = 5; nodes[2].currentTerm = 1;

    /*
    //INITIALIZATION OF THE LEADER
    status[0] = LEADER; 
    logs[0].term = {1, 1, 2, 2, 3}; //give leader highest term
    logs[0].command = {5, 5, 5, 5, 5}; //we'll give leader special commands so we can tell once the leader has replicated
    nodes[0].lastLogIndex = 4; //we have a length 4 log here
    nodes[0].currentTerm = 3;
    lead.id = 0;
    lead.nextIndex = {5, 5, 5}; //initialized to leader.lastLogIndex + 1

    //INITIALIZATION OF 1st FOLLOWER, just needs to append entries
    logs[1].term = {1, 1, 2, 0, 0};
    logs[1].command = {5, 5, 5, 0, 0};
    nodes[1].lastLogIndex = 3;
    nodes[1].currentTerm = 2;

    //INITIALIZATION OF 2nd FOLLOWER, completely messed up logs due to a network partition
    logs[2].term = {1, 1, 1, 1, 1};
    logs[2].command = {1, 1, 1, 1, 1};
    nodes[2].lastLogIndex = 5;
    nodes[2].currentTerm = 1; //at a lower term than the leader so will accept
    */

    //choose a leader, have the leader run appendEntryinPeer on all other nodes. 
    //we want to prove the log matching property 
    int i2;
    for(i2: 1 .. CLUSTER_SIZE - 1) {
        bool appended = FALSE;
        appendEntryInPeer(i2, nodes[0].lastLogIndex, appended);
        do
        :: !appended ->
            appendEntryInPeer(i2, nodes[0].lastLogIndex, appended);
        :: else -> break;
        od;
    }
    //TODO: check that the logs all match
    bool matches = TRUE;
    int j;
    for(j: 1 .. CLUSTER_SIZE - 1) {
        int entry;
        for(entry: 0 .. nodes[lead.id].lastLogIndex) {
            if
            :: logs[j].term[entry] != logs[lead.id].term[entry] || logs[j].command[entry] != logs[lead.id].command[entry] ->
                matches = FALSE;
            :: else -> skip;
            fi;
        }
    }
    logsMatch = matches;
}

ltl one_leader {
    always(
        eventually(logsMatch == TRUE) //the logs all match
    );
}
