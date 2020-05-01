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
    byte nextIndex[CLUSTER_SIZE];
    // byte matchIndex[CLUSTER_SIZE]
}
typedef node {
    byte currentTerm
    byte lastLogIndex
    // byte commitIndex
}
log logs[CLUSTER_SIZE];
//byte commitIndex[CLUSTER_SIZE];
byte state[CLUSTER_SIZE];
lead leader;
node nodes[CLUSTER_SIZE];


inline AppendEntries(leaderTerm, prevLogIndex, prevLogTerm, leaderCommit, self, res) {   
    follower curr = nodes[self];
    if
    :: leaderTerm < curr.currentTerm -> res = FALSE;
    :: logs[self].term[prevLogIndex] != prevLogTerm -> res = FALSE;
    :: else -> res = TRUE;
    fi;

    if //if we are going to append
    :: res ->
        if 
        :: prevLogIndex < curr.lastLogIndex ->
            int j; //prevlogindex is the last index where logs are consistent
            for (j: prevLogIndex + 1 .. MAX_LOG_LENGTH) { //clearing all the log entries in the follower beyond prevLogIndex
                logs[self].term[j] = 0; //0 will indicate not set
                logs[self].command[j] = 0;
            }
            curr.lastLogIndex = prevLogIndex;
        :: else -> skip;
        fi;

        int i = prevLogIndex + 1;
        do 
        :: logs[lead.id].term[i] != 0 -> //while there are logs in the leader to append, change the follower's logs to match the leaders
            logs[self].term[i] = logs[lead.id].term[i];
            logs[self].command[i] = logs[lead.id].command[i];
            curr.lastLogIndex = curr.lastLogIndex + 1; //increment how long your log is
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

inline appendEntryInPeer(peer, lastIndex) {
    leaderNode = nodes[lead.id];
    prevIndex = lead.nextIndex[peer] - 1;
    prevTerm = logs[lead.id].term[prevIndex];
    // leaderCommit = leaderNode.commitIndex;
    appended = FALSE;
    AppendEntries(leaderNode.currentTerm, prevIndex, prevTerm, leaderCommit, peer, appended);
    if
    :: !appended -> 
        lead.nextIndex[peer] = lead.nextIndex[peer] - 1;
        appendEntryInPeer(peer, lastIndex) //check does this work?, will it alter res appropriately?
    : else -> 
        lead.nextIndex[peer] = lastIndex + 1; //updating appropriate maps, we are now done with this peer
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
    for (i: 0.. CLUSTER_SIZE) {
        status[i] = FOLLOWER
    }

    //INITIALIZATION OF THE LEADER
    status[0] = LEADER; 
    logs[0].term = {1, 1, 2, 2, 3}; //give leader highest term
    logs[0].command = {5, 5, 5, 5, 5}; //we'll give leader special commands so we can tell once the leader has replicated
    nodes[0].lastLogIndex = 4; //we have a length 4 log here
    nodes[0].currentTerm = 3;
    lead.id = 0;
    lead.nextIndex = {4, 4, 4}; //initialized to leader.lastLogIndex

    //INITIALIZATION OF 1st FOLLOWER, just needs to append entries
    logs[1].term = {1, 1, 2, 0, 0};
    logs[1].command = {5, 5, 5, 0, 0};
    nodex[1].lastLogIndex = 3;
    nodes[1].currentTerm = 2;

    //INITIALIZATION OF 2nd FOLLOWER, completely messed up logs due to a network partition
    logs[2].term = {1, 1, 1, 1, 1};
    logs[2].command = [1, 1, 1, 1, 1];
    nodes[2].lastIndex = 5;
    nodes[2].currentTerm = 1; //at a lower term than the leader so will accept

    //choose a leader, have the leader run appendEntryinPeer on all other nodes. 
    //we want to prove the log matching property 
    int i;
    for (i: 1 .. CLUSTER_SIZE) {
        appendEntryInPeer(i, nodes[0].lastLogIndex, )
    }
    //TODO: check that the logs all match
}

ltl one_leader {
    always {
        eventually(); //the logs all match
    }
}