/*
log matching property:
if any two distinct log entries have the same term number and the same index then they will store the exact same command and be identical in all the preceding entries 
simulates a leader getting a new message from a client, must send that message to all other noes and if gets a succesful reply then everyone increments commit index
if we can get 
*/
#define CLUSTER_SIZE 3
#define MAX_LOG_LENGTH 256
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
    byte matchIndex[CLUSTER_SIZE]
}
typedef node {
    byte currentTerm
    byte lastLogIndex
    byte commitIndex
}
log logs[CLUSTER_SIZE];
byte commitIndex[CLUSTER_SIZE];
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
            int j = prevLogIndex + 1; //prevlogindex is the last index where logs are consistent
            for (j: 0 .. MAX_LOG_LENGTH) { //clearing all the log entries in the follower beyond prevLogIndex
                logs[self].term[j] = 0; //0 will indicate not set
                logs[self].command[j] = 0;
            }
            curr.lastLogIndex = prevLogIndex;
        :: else -> skip;
        fi;

        int i = prevLogIndex + 1;
        do 
        :: logs[leader.id].term[i] != 0 -> //while there are logs in the leader to append, change the follower's logs to match the leaders
            logs[self].term[i] = logs[leader.id].term[i];
            logs[self].command[i] = logs[leader.id].command[i];
            curr.lastLogIndex = curr.lastLogIndex + 1; //increment how long your log is
        :: else -> break;
        od;

        //updating commitIndex of this node 
        if
        :: leaderCommit > curr.commitIndex ->
            if 
            :: leaderCommit < curr.lastLogIndex -> curr.commitIndex = leaderCommit;
            :: else -> curr.commitIndex = curr.lastLogIndex;
            fi;
        :: else -> skip;
        fi;
    :: else -> skip;
    fi;


}

inline appendEntryInPeer(peer, lastIndex, res) {
    leaderNode = nodes[leader.id];
    prevIndex = leader.nextIndex[peer] - 1;
    prevTerm = logs[leader.id].term[prevIndex];
    leaderCommit = leaderNode.commitIndex;
    appended = FALSE;
    AppendEntries(leaderNode.currentTerm, prevIndex, prevTerm, leaderCommit, peer, appended);
    if
    :: !appended -> 
        leader.nextIndex[peer] = leader.nextIndex[peer] - 1;
        appendEntryInPeer(peer, res) //check does this work?, will it alter res appropriately?
    : else -> 
        leader.nextIndex[peer] = lastIndex + 1; //updating appropriate maps
        leader.matchIndex[peer] = lastIndex;
        if 
        :: lastIndex > leaderNode.commitIndex && logs[leader.id].term[lastIndex] == leader.currentTerm ->
            int count = 0;
            int i;
            for (i: 0 .. CLUSTER_SIZE) {
                if 
                :: leader.matchIndex[i] == lastIndex -> count = count + 1;
                :: else -> skip;
                fi;
            }
            if 
            :: count > (CLUSTER_SIZE/2 + 1) -> 
                leader.commitIndex = lastIndex
                res = TRUE;
            :: else -> skip;
            fi;
        :: else res = FALSE;
    fi;


}

active proctype main() {
    //initialize logs for each node (?) - term should be ascending, length should be randomly determined, contents randomly determined
    //need to initialize where term nor command = 0 ever
    //choose a leader, have the leader run appendEntryinPeer on all other nodes. 
    //we want to prove the log matching property 
}